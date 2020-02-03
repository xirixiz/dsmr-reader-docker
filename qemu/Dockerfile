ARG BASE 
FROM ${BASE}
ARG ARCH
COPY qemu-${ARCH}-static /usr/bin/qemu-${ARCH}-static

ARG VCS_REF
ARG VCS_URL
ARG BUILD_DATE
LABEL org.label-schema.vcs-ref=${VCS_REF} \
      org.label-schema.vcs-url=${VCS_URL} \
org.label-schema.build-date=${BUILD_DATE}
