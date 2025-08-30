#!/bin/bash

set -o errexit
set -o errtrace; trap 'echo "Error ${?} ${BASH_SOURCE[0]:-?}:${LINENO:-?}"' ERR
set -o nounset
set -o pipefail
shopt -s inherit_errexit

cd $(dirname ${0})

echo "** Configure compiler – $(basename ${PWD})"
rm -rf compiler
mkdir compiler

cmake \
  -B compiler \
  -G Ninja \
  -S ../llvm-project/llvm \
  -D CMAKE_C_COMPILER:STRING="clang" \
  -D CMAKE_CXX_COMPILER:STRING="clang++" \
  -D CMAKE_CXX_FLAGS:STRING="-stdlib=libc++" \
  -D CMAKE_EXE_LINKER_FLAGS:STRING="-fuse-ld=lld" \
  -D CMAKE_LINKER:STRING="ld.lld" \
  -D WEBTHING_BUILD_REVISION:STRING="$(cat ../revision)" \
  -D WEBTHING_TARGET_TRIPLE:STRING="$(arch)-webthing-linux" \
  -C ../compiler.cmake

echo "** Build compiler – $(basename ${PWD})"
ninja -j $(nproc) -C compiler

echo "** Install compiler – $(basename ${PWD})"
DESTDIR=${PWD} ninja -C compiler install

mkdir -p System/etc
cat <<EOF > System/etc/$(arch)-webthing-linux-clang.cfg
--sysroot=${PWD}/System
-fPIC
\$-Wl,-dynamic-linker=/System/Libraries/libc.so
\$-Wl,--build-id=none
EOF

cat <<EOF > System/etc/$(arch)-webthing-linux-clang++.cfg
--sysroot=${PWD}/System
-fPIC
-ftrivial-auto-var-init=pattern
\$-Wl,-dynamic-linker=/System/Libraries/libc.so
\$-Wl,--build-id=none
EOF
