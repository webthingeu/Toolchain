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

# Build a compiler, runtime, and libc++ with the host tools.
./compiler.sh
./compiler-libc++.sh

# Add a libc. It is not used by the newly built tools.
./libc.sh

# Add a separate (without an so version) libc++. It is built against our libc.
./libc++.sh

echo "** Export sysroot configuration – $(basename ${PWD})"
cat <<EOF > System/Sysroot.cmake
set(CMAKE_C_COMPILER "/System/bin/clang")
set(CMAKE_CXX_COMPILER "/System/bin/clang++")
set(CMAKE_SYSROOT "/System")
EOF

mv System/lib System/Libraries
ln -sn Libraries System/lib

echo "** Done – $(basename ${PWD})"
