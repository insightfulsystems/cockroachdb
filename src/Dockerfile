ARG BASE
FROM ${BASE} AS runtime
ARG ARCH
ARG COCKROACH_VERSION

RUN apk update \
 && apk add \
    autoconf \
    bash \
    build-base \
    cmake \
    git \
    make \
 && cd /tmp \
 && wget -qO- https://binaries.cockroachdb.com/cockroach-${COCKROACH_VERSION}.src.tgz | tar  xvz \
 && cd cockroach-${COCKROACH_VERSION} \
 && make build \
 && make install \
 && rm -rf /tmp/cockroach-*

ARG VCS_REF
ARG VCS_URL
ARG BUILD_DATE
LABEL org.label-schema.vcs-ref=${VCS_REF} \
      org.label-schema.vcs-url=${VCS_URL} \
org.label-schema.build-date=${BUILD_DATE}

CMD cockroachdb