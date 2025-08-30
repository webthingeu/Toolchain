#!/bin/bash

set -o errexit
set -o errtrace; trap 'echo "Error ${?} ${BASH_SOURCE[0]:-?}:${LINENO:-?}"' ERR
set -o nounset
set -o pipefail
shopt -s inherit_errexit

release=42
packages="\
  automake \
  autoconf-archive \
  bash-completion \
  bc \
  bison \
  coreutils \
  cmake \
  cpio \
  diffutils \
  dnf \
  erofs-utils \
  findutils \
  flex \
  gawk \
  git \
  gn \
  gzip \
  jq \
  less \
  libcxx \
  meson \
  mtools \
  ninja-build \
  openssl \
  perl-FindBin \
  perl-IPC-Cmd \
  pkgconf-pkg-config \
  python3 \
  python3-jinja2 \
  python3-ply \
  python3-yaml \
  rsync \
  strace \
  tar \
  tree \
  veritysetup \
  vim"

echo "** Build – root"

rm -rf root

dnf -y \
  --quiet \
  --use-host-config \
  --no-gpgchecks \
  --setopt=install_weak_deps=False \
  --installroot=${PWD}/root/install \
  --releasever=${release} --disablerepo='*' --enablerepo=fedora,updates \
  install ${packages}

# Avoid to pull-in gcc, manually download and install libtool.
dnf \
  --quiet \
  --use-host-config \
  --no-gpgchecks \
  --releasever=${release} --disablerepo='*' --enablerepo=fedora,updates \
  download libtool

rpm \
  --install \
  --nodeps \
  --nosignature \
  --root=${PWD}/root/install libtool-*rpm
rm libtool-*rpm

rm -rf root/install/usr/{games,local,src,tmp}
rm -rf root/install/usr/lib/sysimage
mv root/install/usr root
rm -rf root/install
ln -s usr/bin root/bin
ln -s usr/lib root/lib
ln -s usr/lib64 root/lib64

cat <<EOF > root/.bashrc
PS1='[\W]\$ '

export HOME=/
export PATH=/System/bin:/usr/bin
export TERM=linux
EOF

chown -R $(stat -c%U:%G .) root
find root -type d -print0 | xargs -0 chmod 755
