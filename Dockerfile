FROM quay.io/vrutkovs/machine-config-operator:spec3-gomod-rework-8ce43ab as mcd

FROM quay.io/coreos-assembler/coreos-assembler:latest AS build
COPY ./entrypoint.sh /usr/bin
COPY --from=mcd /usr/bin/machine-config-daemon /srv/addons/usr/libexec/machine-config-daemon
RUN /usr/bin/entrypoint.sh

FROM scratch
COPY --from=build /srv/ /srv/
ENTRYPOINT ["/noentry"]
