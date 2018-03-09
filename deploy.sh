#!/bin/bash
set -e

echo "[start] Deploy keywords.txt changes."

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

echo "ssh done"

rev=$(git rev-parse --short HEAD)

CHANGELOG_EMAIL=${CHANGELOG_EMAIL:='travis@example.com'}

git config user.name "Travis CI"
git config user.email $CHANGELOG_EMAIL

CHANGELOG_BRANCH=${CHANGELOG_BRANCH:='master'}

#git remote add upstream "https://${GH_REPO_TOKEN}@github.com/$TRAVIS_REPO_SLUG.git"
#git remote add upstream "git@github.com:$TRAVIS_REPO_SLUG.git"
#git fetch upstream
#git checkout $CHANGELOG_BRANCH

git add -A  keywords.txt
git commit -m "updated keywords.txt by ${rev}" -m "[skip ci]"
git push upstream $CHANGELOG_BRANCH

echo "[end] Successful deployed keywords.txt changes."
