#!/bin/sh
set -exuo pipefail

REPO=https://mirror.openshift.com/pub/openshift-v4/dependencies/rpms/4.3-beta/

# TODO: Add machine-config-daemon
PACKAGES=(
  cri-o
  cri-tools
  openshift-hyperkube
  openshift-clients
)

# fetch binaries and configure working env, prow doesn't allow init containers or a second container
dir=/tmp/ostree
mkdir -p "${dir}"
export PATH=$PATH:/tmp/bin
export HOME=/tmp

# extract rpm content in temp dir
mkdir /tmp/working
pushd /tmp/working
  yumdownloader --destdir=/tmp/rpms ${PACKAGES[*]} --repofrompath="ose,${REPO}"
  for i in $(find /tmp/rpms/ -name origin-* -iname *.rpm); do
    echo "Extracting $i ..."
    rpm2cpio $i | cpio -div
  done
  mv etc usr/
popd

# Add binaries to the tree
coreos-assembler dev-overlay --repo /srv/repo --rev fedora/x86_64/coreos/testing-devel --add-tree /tmp/working
