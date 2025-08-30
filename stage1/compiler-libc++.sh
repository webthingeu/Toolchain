#!/bin/bash

set -o errexit
set -o errtrace; trap 'echo "Error ${?} ${BASH_SOURCE[0]:-?}:${LINENO:-?}"' ERR
set -o nounset
set -o pipefail
shopt -s inherit_errexit

cd $(dirname ${0})
rm -rf compiler-libc++
mkdir compiler-libc++

echo "** Configure compiler-libc++ – $(basename ${PWD})"
cmake \
  -B compiler-libc++ \
  -G Ninja \
  -S ../llvm-project/runtimes \
  -D CMAKE_C_COMPILER:STRING="clang" \
  -D CMAKE_CXX_COMPILER:STRING="clang++" \
  -D CMAKE_EXE_LINKER_FLAGS:STRING="-fuse-ld=lld" \
  -D CMAKE_LINKER:STRING="ld.lld" \
  -D WEBTHING_TARGET_TRIPLE:STRING="$(arch)-webthing-linux" \
  -C ../libc++.cmake

echo "** Build compiler-libc++ – $(basename ${PWD})"
ninja -j $(nproc) -C compiler-libc++

echo "** Install compiler-libc++ – $(basename ${PWD})"
DESTDIR=${PWD} ninja -C compiler-libc++ install
