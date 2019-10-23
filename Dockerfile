FROM quay.io/coreos-assembler/coreos-assembler:latest AS build
COPY ./entrypoint.sh /usr/bin
RUN /usr/bin/entrypoint.sh

FROM scratch
COPY --from=build /srv/ /srv/
ENTRYPOINT ["/noentry"]
