# Fetch git repo
echo "[info] fetch repo"
# setup commit user
git config user.name "$CONFIG_VERSION_NAME"
git config user.email $CONFIG_VERSION_EMAIL

#git remote add upstream "https://${GH_REPO_TOKEN}@github.com/$TRAVIS_REPO_SLUG.git"
git remote add upstream "git@github.com:$TRAVIS_REPO_SLUG.git" || true
git fetch upstream
git checkout $CONFIG_VERSION_BRANCH
echo "[ok] fetched repo"


TARGET=${PWD}

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
rm examples

mkdir ${TARGET}/src
mv * ${TARGET}/src

cd ${TARGET}
rm grbl/ -r -f


# commit changes
git add -A && git commit -m "updated remote by ${rev}" -m "[skip ci]" && git push upstream $CONFIG_KEYWORDS_BRANCH || true

