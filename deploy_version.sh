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

# setup ssh-agent and provide the GitHub deploy key
eval "$(ssh-agent -s)"

echo "$SSHKEY" > "sshb64.key"

base64 --decode --ignore-garbage sshb64.key > ssh.key
chmod 600 ssh.key # Allow read access to the private key
ssh-add ssh.key # Add the private key to SSH

echo "[ok] ssh setup done"

# Generate keywords.txt
echo "[info] generate keywords.txt"

NEW_VERSION=1.3.7
sed -i -e 2c"version=${NEW_VERSION}" library.properties
sed -i -e 3c"\"version\": \"${NEW_VERSION}\"," library.json

echo "[ok] generated keywords.txt"

# Deploy
echo "[info] deploy keywords.txt"
rev=$(git rev-parse --short HEAD)

# setup commit user
git config user.name "$CHANGELOG_NAME"
git config user.email $CHANGELOG_EMAIL

#git remote add upstream "https://${GH_REPO_TOKEN}@github.com/$TRAVIS_REPO_SLUG.git"
git remote add upstream "git@github.com:$TRAVIS_REPO_SLUG.git"
git fetch upstream
git checkout $CHANGELOG_BRANCH

# commit changes
git add -A  keywords.txt
git commit -m "updated keywords.txt by ${rev}" -m "[skip ci]"
git push upstream $CHANGELOG_BRANCH

echo "[end] Successful deployed keywords.txt changes."
