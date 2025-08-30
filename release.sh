#!/bin/bash

set -o errexit
set -o errtrace; trap 'echo "Error ${?} ${BASH_SOURCE[0]:-?}:${LINENO:-?}"' ERR
set -o nounset
set -o pipefail
shopt -s inherit_errexit

cd $(dirname ${0})

if [[ -n $(git status --porcelain) ]]; then
  echo "Error: working directory contains changes"
  exit 1
fi

commit=$(git rev-parse HEAD)
branch="webthing-${commit}"

echo "** Committing to branch ${branch}"

if git show-ref --quiet --branches ${branch}; then
  echo "Error: the branch already exists"
  exit 1
fi

export GIT_AUTHOR_NAME=Origin
export GIT_AUTHOR_EMAIL=origin@webthing.eu
export GIT_AUTHOR_DATE="@$(git log -1 --pretty=format:%ct)"
export GIT_COMMITTER_NAME=${GIT_AUTHOR_NAME}
export GIT_COMMITTER_EMAIL=${GIT_AUTHOR_EMAIL}
export GIT_COMMITTER_DATE=${GIT_AUTHOR_DATE}

git branch ${branch}
git checkout ${branch}
rm -rf install
cp -ax --reflink root install
git add install
git commit -m "Release ${branch}"

echo "** Pushing to origin"
git push origin main
git push origin ${branch}
git push -f origin ${branch}:webthing
