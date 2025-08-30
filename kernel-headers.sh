#!/bin/bash

set -o errexit
set -o errtrace; trap 'echo "Error ${?} ${BASH_SOURCE[0]:-?}:${LINENO:-?}"' ERR
set -o nounset
set -o pipefail
shopt -s inherit_errexit

cd $(dirname ${0})

echo "** Install kernel-headers"
rm -rf kernel kernel-headers
make \
  -C ../Kernel/linux/linux \
  O=${PWD}/kernel \
  INSTALL_HDR_PATH=${PWD}/kernel-headers \
  headers_install

rm -rf kernel
