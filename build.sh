#!/bin/bash

set -o errexit
set -o errtrace; trap 'echo "Error ${?} ${BASH_SOURCE[0]:-?}:${LINENO:-?}"' ERR
set -o nounset
set -o pipefail
shopt -s inherit_errexit

if [[ -n "${SUDO_COMMAND:-}" ]]; then
  echo "Error: sudo detected"
  exit 1
fi

if [[ "$(git rev-parse --abbrev-ref HEAD)" != "main" ]]; then
  echo "Error: main branch required"
  exit 1
fi

if [[ -n $(git status --porcelain) ]]; then
  echo "Error: working directory contains changes"
  exit 1
fi

cd $(dirname ${0})

# The chroot cannot access git when we are a submodule.
git log --format=%h -1 > revision

./kernel-headers.sh

# Build a root filesystem.
sudo ./root.sh

# Build a toolchain with the host tools.
stage1/build.sh

# Build our toolchain with the stage1 tools in the root filesystem.
stage2/build.sh

# Move our toolchain into the root filesystem.
cp -ax --reflink stage2/System root

function normalizeSONAME() {
  local dir=${1}

  for i in $(find ${dir} -maxdepth 1 -type l -printf '%f\n'); do
    local line=$(readelf --dynamic ${dir}/${i} | grep '(SONAME)' ||:)
    if [[ -z "${line}" ]]; then
      continue
    fi

    local soname=$(echo ${line}| sed 's#.*: \[\(.*\)\].*#\1#')
    if [[ -z "${soname}" ]]; then
      continue
    fi

    # Skip the link to the SONAME, it will be replaced below.
    if [[ ${i} == ${soname} ]]; then
      continue
    fi

    local target=$(readlink ${dir}/${i})
    if [[ ${soname} == ${target} ]]; then
      continue
    fi

    # Update the link to point to the SONAME.
    ln -snf ${soname} ${dir}/${i}
  done

  for i in $(find ${dir} -maxdepth 1 -type f -name "*.so*" -printf '%f\n'); do
    local line=$(readelf --dynamic ${dir}/${i} | grep '(SONAME)' ||:)
    if [[ -z "${line}" ]]; then
      continue
    fi

    local soname=$(echo ${line}| sed 's#.*: \[\(.*\)\].*#\1#')
    if [[ -z "${soname}" ]]; then
      continue
    fi

    if [[ ${i} == ${soname} ]]; then
      continue
    fi

    mv -f ${dir}/${i} ${dir}/${soname}
  done
}

normalizeSONAME root/System/Libraries

# Unify file permissions.
find root/System/Libraries -type f | xargs chmod 0644

find root/System -type f -executable | xargs strip --strip-all --remove-section=.comment 2>/dev/null ||:
find root/System/Libraries -type f -name "*.so*" | xargs strip --strip-all --remove-section=.comment

# The libc itself is executed as the ELF dynamic linker.
chmod 0755 root/System/Libraries/libc.so

