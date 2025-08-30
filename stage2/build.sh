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

cd $(dirname ${0})
rm -rf System
mkdir System
cp -a ../kernel-headers/include System

# Create a root with the stage1 toolchain.
rm -rf build
cp -ax --reflink ../root build
rm -rf build/System
cp -ax --reflink ../stage1/System build

# Build a compiler, runtime, libc, and libc++ with the stage1 tools.
./chroot.sh /Toolchain/stage2/compiler.sh
./chroot.sh /Toolchain/stage2/libc.sh
./chroot.sh /Toolchain/stage2/libc++.sh

echo "** Export sysroot configuration – $(basename ${PWD})"
cat <<EOF > System/Sysroot.cmake
set(CMAKE_C_COMPILER "/System/bin/clang")
set(CMAKE_CXX_COMPILER "/System/bin/clang++")
set(CMAKE_SYSROOT "/System")
EOF

mv System/lib System/Libraries
ln -sn Libraries System/lib

echo "** Done – $(basename ${PWD})"
