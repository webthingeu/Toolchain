#!/bin/bash

set -o errexit
set -o errtrace; trap 'echo "Error ${?} ${BASH_SOURCE[0]:-?}:${LINENO:-?}"' ERR
set -o nounset
set -o pipefail
shopt -s inherit_errexit

cd $(dirname ${0})

rm -rf libc++
mkdir libc++

echo "** Configure libc++ – $(basename ${PWD})"
cmake \
  -B libc++ \
  -G Ninja \
  -S ../llvm-project/runtimes \
  -D CMAKE_C_COMPILER:STRING="${PWD}/System/bin/clang" \
  -D CMAKE_CXX_COMPILER:STRING="${PWD}/System/bin/clang++" \
  -D CMAKE_EXE_LINKER_FLAGS:STRING="-fuse-ld=lld" \
  -D CMAKE_PLATFORM_NO_VERSIONED_SONAME:BOOL=ON \
  -D LIBCXX_HAS_MUSL_LIBC:BOOL=ON \
  -D WEBTHING_TARGET_TRIPLE:STRING="$(arch)-webthing-linux" \
  -C ../libc++.cmake

echo "** Build libc++ – $(basename ${PWD})"
ninja -j $(nproc) -C libc++

echo "** Install libc++ – $(basename ${PWD})"
DESTDIR=${PWD} ninja -C libc++ install
