#!/bin/bash
set -e

CONFIG_EX_AUTOFORMAT_NAME=${CONFIG_EX_AUTOFORMAT_NAME:='Travis CI'}
CONFIG_EX_AUTOFORMAT_EMAIL=${CONFIG_EX_AUTOFORMAT_EMAIL:='travis@example.com'}
CONFIG_EX_AUTOFORMAT_BRANCH=${CONFIG_EX_AUTOFORMAT_BRANCH:='master'}

echo "[start] Generate and deploy keywords.txt changes."

# Not on pull request or development branches
if [ "$TRAVIS_PULL_REQUEST" != "false" ]; then
  echo "[abort] This commit is a pull request!"
  exit 0
fi
if [ "$TRAVIS_BRANCH" != "$CONFIG_EX_AUTOFORMAT_BRANCH" ]; then
  echo "[abort] This commit was made against the $TRAVIS_BRANCH and not $CONFIG_EX_AUTOFORMAT_BRANCH!"
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
echo "[info] format examples"
find examples -name '*.ino' -exec astyle --options=formatter.conf {} \;
echo "[ok] formated examples"

# Deploy
echo "[info] deploy examples"
rev=$(git rev-parse --short HEAD)

# setup commit user
git config user.name "$CONFIG_EX_AUTOFORMAT_NAME"
git config user.email $CONFIG_EX_AUTOFORMAT_EMAIL

#git remote add upstream "https://${GH_REPO_TOKEN}@github.com/$TRAVIS_REPO_SLUG.git"
git remote add upstream "git@github.com:$TRAVIS_REPO_SLUG.git"
git fetch upstream
git checkout $CONFIG_EX_AUTOFORMAT_BRANCH

# commit changes
git add -A  keywords.txt && git commit -m "autoformat examples by ${rev}" -m "[skip ci]" && git push upstream $CONFIG_EX_AUTOFORMAT_BRANCH || true

echo "[end] Successful deployed examples changes."

exit 0
