#!/bin/bash

set -o errexit
set -o errtrace; trap 'echo "Error ${?} ${BASH_SOURCE[0]:-?}:${LINENO:-?}"' ERR
set -o nounset
set -o pipefail
shopt -s inherit_errexit

cd $(dirname ${0})

echo "** Configure libc – $(basename ${PWD})"
rm -rf libc
mkdir libc

export CC=${PWD}/System/bin/clang
export CC_LD=${PWD}/System/bin/ld.lld
export LIBCC="-lclang_rt.builtins"
(cd libc &&
  ../../musl/configure \
  --prefix=/System \
  --syslibdir=/System/lib \
  --disable-static \
  --disable-wrapper)

echo "** Build libc – $(basename ${PWD})"
make --silent -j 2 -C libc

echo "** Install libc – $(basename ${PWD})"
DESTDIR=${PWD} make --silent -C libc install
rm -f System/lib/ld-musl-*
