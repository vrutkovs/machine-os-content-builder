FROM registry.svc.ci.openshift.org/vrutkovs/machine-config-operator@sha256:b8d7a44f208bf27aee907acdd4c3b6f07200dd7f5ca6d7ebd86499cdf378f7ce as mcd
FROM quay.io/openshift/origin-artifacts:4.6 as artifacts

FROM quay.io/coreos-assembler/coreos-assembler:latest AS build
COPY --from=mcd /usr/bin/machine-config-daemon /srv/addons/usr/libexec/machine-config-daemon
COPY --from=artifacts /srv/repo/*.rpm /tmp/rpms/
USER 0
COPY ./entrypoint.sh /usr/bin
RUN /usr/bin/entrypoint.sh

FROM scratch
COPY --from=build /srv/ /srv/
COPY --from=build /extensions/ /extensions/
ENTRYPOINT ["/noentry"]
