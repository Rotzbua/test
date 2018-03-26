#!/bin/bash
set -e

CONFIG_REMOTE_NAME=${CONFIG_REMOTE_NAME:='Travis CI'}
CONFIG_REMOTE_EMAIL=${CONFIG_REMOTE_EMAIL:='travis@example.com'}
CONFIG_REMOTE_BRANCH=${CONFIG_REMOTE_BRANCH:='test'}
TARGET=${PWD}
TARGET=$TRAVIS_BUILD_DIR
# care, do not run script more than once a day!
deployTag=`date +%Y.%m.%d`

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


COPY_GIT=https://github.com/gnea/grbl

# cleanup repository
#rm grbl/ -r -f
find ! -path '*/.*' -delete

git clone --depth=1 ${COPY_GIT}.git

cd grbl

latestTag=$(git describe --tags `git rev-list --tags --max-count=1`)

echo ${latestTag}

#git clone -b 'v2.0' --single-branch --depth 1 https://github.com/git/git.git

git fetch --tags

git checkout $latestTag

# move license
mv COPYING ${TARGET}/LICENSE
# move doc
mv README.md ${TARGET}/README2.md
echo -e "# This is a autodeployed library\n"> ${TARGET}/README.md
echo -e "Remote repository: ${COPY_GIT}\n" >> ${TARGET}/README.md
echo -e "Remote tag: [${latestTag}](${COPY_GIT}/tree/${latestTag})\n" >> ${TARGET}/README.md
echo -e "Local tag: [${deployTag}](./tree/${deployTag})\n" >> ${TARGET}/README.md
echo -e "Original readme: [REAMDE2.md](./blob/README2.md)\n" >> ${TARGET}/README.md
echo -e "License: [LICENSE](./blob/LICENSE)\n" >> ${TARGET}/README.md
echo -e "## Restrictions\n" >> ${TARGET}/README.md
echo -e "* No bugfixes" >> ${TARGET}/README.md
echo -e "* No issue tracker" >> ${TARGET}/README.md
echo -e "* No support\n" >> ${TARGET}/README.md
echo -e "## Features\n" >> ${TARGET}/README.md
echo -e "* Automatically deploys newest tag of the according git" >> ${TARGET}/README.md
echo -e "* Adds support for Arduino library\n" >> ${TARGET}/README.md
echo -e "## Autor: Rotzbua" >> ${TARGET}/README.md
mkdir -p ${TARGET}/extras
mv doc/ ${TARGET}/extras/

# enter source code folder
cd grbl

# move examples
#cd examples
#mkdir -p ${TARGET}/examples
#mv * ${TARGET}/examples
#cd ..
#rm -r examples
mv examples/ ${TARGET}/

# move source files
mkdir -p ${TARGET}/src
mv *.h ${TARGET}/src
mv *.c ${TARGET}/src
mv *.hpp ${TARGET}/src || true
mv *.cpp ${TARGET}/src || true

# remove temporary downloaded git
cd ${TARGET}
rm grbl/ -r -f


# commit changes
git add -A
#git rm --cached ssh.key
git commit -m "updated remote by ${latestTag}" -m "[skip ci]" && git commit -m "ready for version ${deployTag}" --allow-empty
git push upstream $CONFIG_REMOTE__BRANCH

