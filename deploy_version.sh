#!/bin/bash
set -e

CHANGELOG_NAME=${CHANGELOG_NAME:='Travis CI'}
CHANGELOG_EMAIL=${CHANGELOG_EMAIL:='travis@example.com'}
CHANGELOG_BRANCH=${CHANGELOG_BRANCH:='master'}

echo "[start] Update and deploy version."

# Not on pull request or development branches
if [ "$TRAVIS_PULL_REQUEST" != "false" ]; then
  echo "[abort] This commit is a pull request!"
  exit 0
fi
if [ "$TRAVIS_BRANCH" != "$CHANGELOG_BRANCH" ]; then
  echo "[abort] This commit was made against the $TRAVIS_BRANCH and not $CHANGELOG_BRANCH!"
  exit 0
fi
# Just on push
if [ "$TRAVIS_EVENT_TYPE" != "push" ]; then
  echo "[abort] Can be only triggered by 'push' event!"
  exit 0
fi

# grab version
regex_sanity="(ready for version )([0-9]+\.[0-9]+\.[0-9]+)+"
regex_version="([0-9]+\.[0-9]+\.[0-9]+)+"
var="$TRAVIS_COMMIT_MESSAGE"

if [[ "$var" =~ $regex_sanity ]]
then
	echo "sanity: version found"
else
	echo "sanity: no version found"
	exit 0
fi

if [[ "$var" =~ $regex_version ]]
then
	NEW_VERSION="$BASH_REMATCH"
	echo "found version, we try to deploy version: $NEW_VERSION"
else
	echo "no version found"
	exit 0
fi

# setup ssh-agent and provide the GitHub deploy key
eval "$(ssh-agent -s)"

echo "$SSHKEY" > "sshb64.key"

base64 --decode --ignore-garbage sshb64.key > ssh.key
chmod 600 ssh.key # Allow read access to the private key
ssh-add ssh.key # Add the private key to SSH

echo "[ok] ssh setup done"

# Fetch git repo
echo "[info] fetch repo"
# setup commit user
git config user.name "$CHANGELOG_NAME"
git config user.email $CHANGELOG_EMAIL

#git remote add upstream "https://${GH_REPO_TOKEN}@github.com/$TRAVIS_REPO_SLUG.git"
git remote add upstream "git@github.com:$TRAVIS_REPO_SLUG.git"
git fetch upstream
git checkout $CHANGELOG_BRANCH
echo "[ok] fetched repo"

# Generate keywords.txt
echo "[info] generate version"

sed -i -e 2c"version=${NEW_VERSION}" library.properties
sed -i -e 3c"\s\s\"version\": \"${NEW_VERSION}\"," library.json

echo "[ok] generated version"

# Deploy
echo "[info] deploy version"
rev=$(git rev-parse --short HEAD)
# commit changes
git add -A  library.properties
git add -A  library.json
git commit -m "bumped version to ${NEW_VERSION} by ${rev}" -m "[skip ci]"
git push upstream $CHANGELOG_BRANCH

echo "[end] Successful deployed version changes."

exit 0