https://origin-release.svc.ci.openshift.org/

# Images included in the release
`oc adm -a /path/to/pull_secret.json release info registry.svc.ci.openshift.org/origin/release:4.3`

Name:          4.3.0-0.okd-2019-10-29-180250
Digest:        sha256:68286e07f7d68ebc8a067389aabf38dee9f9b810c5520d6ee4593c38eb48ddc9
Created:       2019-10-29T18:02:57Z
OS/Arch:       linux/amd64
Manifests:     343
Unknown files: 3

Pull From: registry.svc.ci.openshift.org/origin/release@sha256:68286e07f7d68ebc8a067389aabf38dee9f9b810c5520d6ee4593c38eb48ddc9

Release Metadata:
  Version:  4.3.0-0.okd-2019-10-29-180250
  Upgrades: <none>

Component Versions:
  Kubernetes 1.16.2

Images:
  NAME                                          DIGEST
  aws-machine-controllers                       sha256:2b0c1ebc7e91a02d1f6d9a4345b978710162cca51b7d971a72086bbe6c302f93
  azure-machine-controllers                     sha256:665ad7825e26e3a132c17f9c56d48ece90979b17c6668b31c4255abc299a252e
  baremetal-installer                           sha256:2bc27120c63d4a2255a6b3eefd95472e2884c7a9191491468d14309370e0c550
  baremetal-machine-controllers                 sha256:329b3275ba21b22c2755d060f5f23b22f79bc9d300a30aad9c4d474e71023f77
  baremetal-operator                            sha256:c16835b85afc6d2a649089afb75697ffe002629a72a2443896e6a3134d7aa009
  baremetal-runtimecfg                          sha256:8c3b0223699801a9cb93246276da4746fa4d6fa66649929b2d9b702c17dac75d
  branding                                      sha256:2fb51915a0b79615f71321f96c3e48ee743df32fc49e9edad48193b6f91a3cd9
  ...
  machine-config-operator                       sha256:c9dcbb935e24e4d1d227d69655978ddec13a4e03840d081e76531c903575d360
  machine-os-content                            sha256:88406db92d5249d005226cb87adef0fd28cd9e5a73e76eb2d60499c6108fafb0
  mdns-publisher                                sha256:768194132b4dbde077e32de8801c952265643da00ae161f1ee560fabf6ed1f8e
  ...

# Show commit URLs for images in the release
`oc adm -a /path/to/pull_secret.json release info registry.svc.ci.openshift.org/origin/release:4.3 --commit-urls`
  ...
  Images:
  NAME                                          URL
  aws-machine-controllers                       https://github.com/openshift/cluster-api-provider-aws/commit/6814fc34f30a4c98d5edeb0a4ef73bbd03fa959b
  azure-machine-controllers                     https://github.com/openshift/cluster-api-provider-azure/commit/c1d771c6c17a00b9c07f8b17484d170fe8dc0ed0
  baremetal-installer                           https://github.com/openshift/installer/commit/a9d73356bfc5046b1d66f674bb46df10199b83a4
  baremetal-machine-controllers                 https://github.com/openshift/cluster-api-provider-baremetal/commit/a2a477909c1d518ef7cf28601e5d7db56a4d4069
...

# Mirror release images
```
oc adm -a /path/to/pull_secret.json \
  release mirror \
  --from registry.svc.ci.openshift.org/origin/release:4.3
  --to quay.io/vrutkovs/okd-release
  --to-release-image quay.io/vrutkovs/okd-release:4.3
```

# Create a new release with an image replaced
```
oc adm -a /home/vrutkovs/auth_ci.json \
  release new \
  --from-release quay.io/vrutkovs/okd-release:4.3 \
  --to-image quay.io/vrutkovs/okd-release:4.3-network-updated \
  cluster-network-operator=quay.io/vrutkovs/cluster-network-operator:fixed-version
```
It also includes amendment for `install-config.yaml` to add after its mirrored

# Run installer with a new release
```
export OPENSHIFT_INSTALL_RELEASE_IMAGE_OVERRIDE=quay.io/vrutkovs/okd-release:4.3-network-updated
openshift-install create cluster ...
```

# Advanced topics

# OKD-on-FCOS 4.3 specifics

* openshift-installer from `fcos` branch
* machine-config-daemon from `fcos` branch

Please add `[FCOS]` tag to your contribution

## Mixing binaries in your own machine-os-content

https://github.com/vrutkovs/machine-os-content-builder

## Entirely different OS base?

See https://github.com/coreos/coreos-assembler to build your own (rpm-)ostree based OS.
FCOS configuration: https://github.com/coreos/fedora-coreos-config/
