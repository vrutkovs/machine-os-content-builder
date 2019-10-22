FROM quay.io/coreos-assembler/coreos-assembler:latest AS build
COPY --from=registry.svc.ci.openshift.org/fcos/machine-os-content:4.3 /srv/ /srv/
COPY ./entrypoint.sh /usr/bin
RUN chmod +x /usr/bin/entrypoint.sh && \
    /usr/bin/entrypoint.sh

FROM scratch
COPY --from=build /srv/ /srv/
