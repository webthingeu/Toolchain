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
  -D CMAKE_C_COMPILER:STRING="/System/bin/clang" \
  -D CMAKE_CXX_COMPILER:STRING="/System/bin/clang++" \
  -D CMAKE_TOOLCHAIN_FILE:STRING="${PWD}/../stage1/System/Sysroot.cmake" \
  -D WEBTHING_BUILD_REVISION:STRING="$(cat ../revision)" \
  -D WEBTHING_TARGET_TRIPLE:STRING="$(arch)-webthing-linux" \
  -C ../compiler.cmake

echo "** Build compiler – $(basename ${PWD})"
ninja -j $(nproc) -C compiler

echo "** Install compiler – $(basename ${PWD})"
DESTDIR=${PWD} ninja -C compiler install
ln -sn llvm-readobj System/bin/llvm-readelf

mkdir -p System/etc
cat <<EOF > System/etc/$(arch)-webthing-linux-clang.cfg
--sysroot=/System
-fPIC
\$-Wl,-dynamic-linker=/System/Libraries/libc.so
\$-Wl,--build-id=none
EOF

cat <<EOF > System/etc/$(arch)-webthing-linux-clang++.cfg
--sysroot=/System
-fPIC
-D_LIBCPP_HAS_MUSL_LIBC
-ftrivial-auto-var-init=pattern
\$-Wl,-dynamic-linker=/System/Libraries/libc.so
\$-Wl,--build-id=none
EOF
