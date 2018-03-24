#!/bin/bash
set -e

CONFIG_REMOTE_NAME=${CONFIG_REMOTE_NAME:='Travis CI'}
CONFIG_REMOTE_EMAIL=${CONFIG_REMOTE_EMAIL:='travis@example.com'}
CONFIG_REMOTE_BRANCH=${CONFIG_REMOTE_BRANCH:='test'}
TARGET=${PWD}
TARGET=$TRAVIS_BUILD_DIR

# setup ssh-agent and provide the GitHub deploy key
eval "$(ssh-agent -s)"

echo "$SSHKEY" > "sshb64.key"

base64 --decode --ignore-garbage sshb64.key > ssh.key
rm sshb64.key
chmod 600 ssh.key # Allow read access to the private key
ssh-add ssh.key # Add the private key to SSH

echo "[ok] ssh setup done"

# Fetch git repo
echo "[info] fetch repo"

cd ${TARGET}

# setup commit user
git config user.name "$CONFIG_REMOTE_NAME"
git config user.email $CONFIG_REMOTE_EMAIL

#git remote add upstream "https://${GH_REPO_TOKEN}@github.com/$TRAVIS_REPO_SLUG.git"
git remote add upstream "git@github.com:$TRAVIS_REPO_SLUG.git" 
git fetch upstream
git checkout $CONFIG_REMOTE_BRANCH
echo "[ok] fetched repo"



rm grbl/ -r -f
git clone --depth=1 https://github.com/gnea/grbl.git

cd grbl

latestTag=$(git describe --tags `git rev-list --tags --max-count=1`)

echo ${latestTag}

#git clone -b 'v2.0' --single-branch --depth 1 https://github.com/git/git.git

git fetch --tags

git checkout $latestTag

#rm -r .git

cd grbl

cd examples

mkdir ${TARGET}/examples
mv * ${TARGET}/examples

cd ..
rm -r examples

mkdir ${TARGET}/src
mv * ${TARGET}/src

cd ${TARGET}
rm grbl/ -r -f


# commit changes
git add -A
git rm --cached ssh.key
git commit -m "updated remote by ${rev}" -m "[skip ci]"
git push upstream $CONFIG_REMOTE__BRANCH

