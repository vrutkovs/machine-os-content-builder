#!/bin/sh
set -exuo pipefail

REPOS=(
  https://mirror.openshift.com/pub/openshift-v4/dependencies/rpms/4.3-beta2/
)
tar_url="http://192.168.1.155:8000/builds/latest/x86_64/centos-coreos-8.20200224.dev.0-ostree.x86_64.tar"
REF="centos/x86_64/coreos/testing-devel"

# openshift-hyperkube and openshift-clients would already be placed in /tmp/rpms
PACKAGES=(
  cri-o
  cri-tools
  conmon
  runc
  slirp4netns
  openshift-hyperkube
)

# fetch binaries and configure working env, prow doesn't allow init containers or a second container
dir=/tmp/ostree
mkdir -p "${dir}"
export PATH=$PATH:/tmp/bin
export HOME=/tmp

# fetch jq binary
mkdir $HOME/bin
curl -L https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 2>/dev/null >/tmp/bin/jq
chmod ug+x $HOME/bin/jq

# fetch existing machine-os-content
mkdir /srv/repo
curl -L "${tar_url}" | tar xf - -C /srv/repo/ --no-same-owner

# use repos from FCOS
rm -rf /etc/yum.repos.d
ostree --repo=/srv/repo checkout "${REF}" --subpath /usr/etc/yum.repos.d --user-mode /etc/yum.repos.d
dnf clean all

REPOLIST=""
for i in "${!REPOS[@]}"; do
  REPOLIST="${REPOLIST} --repofrompath=repo${i},${REPOS[$i]}"
done

# extract rpm content in temp dir
mkdir /tmp/working
pushd /tmp/working
  yumdownloader --archlist=x86_64 --disablerepo='*' --destdir=/tmp/rpms ${REPOLIST} ${PACKAGES[*]}
  for i in $(find /tmp/rpms/ -iname *.rpm); do
    echo "Extracting $i ..."
    rpm2cpio $i | cpio -div
  done
  mv etc usr/
  # crio is creating /opt/cni, which would break dev-overlay
  rm -rf opt/
  rm -rf sbin
popd

# add binaries from /srv/addons
mkdir -p /tmp/working/usr/bin
cp -rvf /srv/addons/* /tmp/working/

# Add binaries to the tree
coreos-assembler dev-overlay --repo /srv/repo --rev "${REF}" --add-tree /tmp/working --output-ref "${REF}"
