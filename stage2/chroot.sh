#!/bin/bash

set -o errexit
set -o errtrace; trap 'echo "Error ${?} ${BASH_SOURCE[0]:-?}:${LINENO:-?}"' ERR
set -o nounset
set -o pipefail
shopt -s inherit_errexit
set -e

cd $(dirname ${0})

if [[ ! -d build ]]; then
  echo "Error: missing 'build' directory"
  exit 1
fi

# Open new mount, net, pid, user namespace. Clear environment
# and re-execute ourselves. We appear to run as root, PID1 and
# have no network access.
if [[ $$ != 1 ]]; then
  exec -c unshare \
    --mount \
    --net \
    --pid --fork \
    --map-root-user \
    ./$(basename ${0}) ${@}
fi

export HOME=/
export PATH=/System/bin:/usr/bin
export TERM=linux

function deviceNode() {
  local name=${1}

  touch build/dev/${name}
  mount --bind /dev/${name} build/dev/${name}
}

# We do not have the capability to create device nodes, bind-mount them.
mkdir -p build/{dev,proc,tmp}
deviceNode null
deviceNode random
deviceNode urandom

mount -t proc none build/proc

mkdir -p build/Toolchain
mount --bind .. build/Toolchain

exec chroot build ${@:-bash}
