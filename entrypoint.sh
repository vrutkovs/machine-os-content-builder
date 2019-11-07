#!/bin/sh
set -exuo pipefail

REPOS=(
  ose
  https://mirror.openshift.com/pub/openshift-v4/dependencies/rpms/4.3-beta/
  https://vrutkovs.github.io/okd-on-fcos-fixes
)
STREAM="testing-devel"
REF="fedora/x86_64/coreos/${STREAM}"

PACKAGES=(
  cri-o
  cri-tools
  openshift-hyperkube
  openshift-clients
  nfs-utils-coreos
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
curl -L "${tar_url}" | tar xf - -C /srv/repo/

# extract rpm content in temp dir
mkdir /tmp/working
pushd /tmp/working
  REPO=$(printf "%s," "${REPOS[@]}")
  yumdownloader --disablerepo='*' --destdir=/tmp/rpms ${PACKAGES[*]} --repofrompath="${REPO::-1}"
  for i in $(find /tmp/rpms/ -iname *.rpm); do
    echo "Extracting $i ..."
    rpm2cpio $i | cpio -div
  done
  mv etc usr/
popd

# add binaries from /srv/addons
mkdir -p /tmp/working/usr/bin
cp -rvf /srv/addons/* /tmp/working/

# Add binaries to the tree
coreos-assembler dev-overlay --repo /srv/repo --rev "${REF}" --add-tree /tmp/working --output-ref "${REF}"
