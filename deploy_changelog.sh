#!/bin/bash
set -e

CONFIG_KEYWORDS_NAME=${CONFIG_KEYWORDS_NAME:='Travis CI'}
CONFIG_KEYWORDS_EMAIL=${CONFIG_KEYWORDS_EMAIL:='travis@example.com'}
CONFIG_KEYWORDS_BRANCH=${CONFIG_KEYWORDS_BRANCH:='master'}

echo "[start] Generate and deploy keywords.txt changes."

# Not on pull request or development branches
if [ "$TRAVIS_PULL_REQUEST" != "false" ]; then
  echo "[abort] This commit is a pull request!"
  exit 0
fi
if [ "$TRAVIS_BRANCH" != "$CONFIG_KEYWORDS_BRANCH" ]; then
  echo "[abort] This commit was made against the $TRAVIS_BRANCH and not $CONFIG_KEYWORDS_BRANCH!"
  exit 0
fi
# Just on push
if [ "$TRAVIS_EVENT_TYPE" != "push" ]; then
  echo "[abort] Can be only triggered by 'push' event!"
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
echo "[info] install github_changelog_generator"
gem install github_changelog_generator
echo "[info] generate changelog"
github_changelog_generator $TRAVIS_REPO_SLUG --unreleased --token=${GH_REPO_TOKEN}

echo "[ok] generated changelog"

# Deploy
echo "[info] deploy keywords.txt"
rev=$(git rev-parse --short HEAD)

# setup commit user
git config user.name "$CONFIG_KEYWORDS_NAME"
git config user.email $CONFIG_KEYWORDS_EMAIL

#git remote add upstream "https://${GH_REPO_TOKEN}@github.com/$TRAVIS_REPO_SLUG.git"
git remote add upstream "git@github.com:$TRAVIS_REPO_SLUG.git"
git fetch upstream
git checkout $CONFIG_KEYWORDS_BRANCH

# commit changes
git add -A  CHANGELOG.md && git commit -m "updated changelog.txt by ${rev}" -m "[skip ci]" && git push upstream $CONFIG_KEYWORDS_BRANCH || true

echo "[end] Successful deployed keywords.txt changes."

exit 0