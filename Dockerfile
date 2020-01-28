FROM quay.io/openshift/origin-machine-config-operator:4.4 as mcd

FROM quay.io/coreos-assembler/coreos-assembler:latest AS build
COPY ./entrypoint.sh /usr/bin
COPY --from=mcd /usr/bin/machine-config-daemon /srv/addons/usr/libexec/machine-config-daemon
RUN /usr/bin/entrypoint.sh

FROM scratch
COPY --from=build /srv/ /srv/
ENTRYPOINT ["/noentry"]
