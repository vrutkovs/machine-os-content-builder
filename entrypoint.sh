#!/bin/sh
set -exuo pipefail

REPOS=()
STREAM="testing-devel"
REF="fedora/x86_64/coreos/${STREAM}"

# openshift-hyperkube and openshift-clients would already be placed in /tmp/rpms
PACKAGES=(
  cri-o
  cri-tools
  attr
  glusterfs
  glusterfs-client-xlators
  glusterfs-fuse
  glusterfs-libs
  psmisc
  NetworkManager-ovs
  openvswitch
  dpdk
  gdbm-libs
  libxcrypt-compat
  python-pip-wheel
  python-setuptools-wheel
  python-unversioned-command
  python3
  python3-libs
  python3-pip
  python3-setuptools
  unbound-libs
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

# fetch fcos release info and check whether we've already built this image
build_url="https://builds.coreos.fedoraproject.org/prod/streams/${STREAM}/builds"
curl "${build_url}/builds.json" 2>/dev/null >${dir}/builds.json
build_id="$( <"${dir}/builds.json" jq -r '.builds[0].id' )"
base_url="${build_url}/${build_id}/x86_64"
curl "${base_url}/meta.json" 2>/dev/null >${dir}/meta.json
tar_url="${base_url}/$( <${dir}/meta.json jq -r .images.ostree.path )"
commit_id="$( <${dir}/meta.json jq -r '."ostree-commit"' )"

# fetch existing machine-os-content
mkdir /srv/repo
curl -L "${tar_url}" | tar xf - -C /srv/repo/ --no-same-owner

# use repos from FCOS
rm -rf /etc/yum.repos.d
ostree --repo=/srv/repo checkout "${REF}" --subpath /usr/etc/yum.repos.d --user-mode /etc/yum.repos.d
dnf clean all

# enable crio 1.18
sed -i 's/enabled=0/enabled=1/g' /etc/yum.repos.d/fedora-updates-testing-modular.repo
dnf module enable -y cri-o:1.18

REPOLIST="--enablerepo=fedora --enablerepo=updates --enablerepo=updates-testing-modular"
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
  # /sbin is a symlink to /usr/sbin
  mv sbin/* usr/sbin/
  rm -rf sbin
popd

# add binaries from /srv/addons
mkdir -p /tmp/working/usr/bin
cp -rvf /srv/addons/* /tmp/working/

# Add binaries to the tree
coreos-assembler dev-overlay --repo /srv/repo --rev "${REF}" --add-tree /tmp/working --output-ref "${REF}"
