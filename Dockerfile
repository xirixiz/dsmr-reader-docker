#---------------------------------------------------------------------------------------------------------------------------
# STAGING STEP
#---------------------------------------------------------------------------------------------------------------------------

FROM --platform=$BUILDPLATFORM python:3.11-alpine3.19 as staging
WORKDIR /app

ARG DSMR_VERSION
ENV DSMR_VERSION=${DSMR_VERSION:-5.0.0}

RUN echo "**** Download DSMR ****" \
  && apk add --no-cache curl \
  && curl -SskLf "https://github.com/dsmrreader/dsmr-reader/archive/refs/tags/v${DSMR_VERSION}.tar.gz" | tar xvzf - --strip-components=1 -C /app \
  && curl -SskLf "https://raw.githubusercontent.com/dsmrreader/dsmr-reader/v5/dsmr_datalogger/scripts/dsmr_datalogger_api_client.py" -o /app/dsmr_datalogger_api_client.py

#---------------------------------------------------------------------------------------------------------------------------
# BUILD STEP
#---------------------------------------------------------------------------------------------------------------------------
FROM python:3.11-alpine3.19 as base

# Build the binary according to the TARGET platform variables
ARG TARGETARCH
ARG TARGETVARIANT

ARG QEMU_ARCH
ARG S6_VERSION="3.1.6.2"
ARG DOCKER_TARGET_RELEASE
ARG DSMR_VERSION

ENV PS1="$(whoami)@dsmr_reader_docker:$(pwd)\\$ " \
  TERM="xterm"

ENV QEMU_ARCH=${QEMU_ARCH:-x86_64} \
  DSMR_VERSION=${DSMR_VERSION} \
  DOCKER_TARGET_RELEASE=${DOCKER_TARGET_RELEASE} \
  PIP_NO_CACHE_DIR=1 \
  S6_SERVICES_GRACETIME=30000 \
  S6_CMD_WAIT_FOR_SERVICES_MAXTIME=0

ENV DJANGO_SECRET_KEY=dsmrreader \
  DJANGO_DATABASE_ENGINE=django.db.backends.postgresql \
  DSMRREADER_SUPPRESS_STORAGE_SIZE_WARNINGS=True \
  DJANGO_DATABASE_NAME=dsmrreader \
  DJANGO_DATABASE_USER=dsmrreader \
  DJANGO_DATABASE_PASSWORD=dsmrreader \
  DJANGO_DATABASE_HOST=dsmrdb \
  DJANGO_DATABASE_PORT=5432 \
  DSMRREADER_ADMIN_USER=admin \
  DSMRREADER_ADMIN_PASSWORD=admin \
  DSMRREADER_OPERATION_MODE=standalone \
  VACUUM_DB_ON_STARTUP=false \
  DSMRREADER_REMOTE_DATALOGGER_INPUT_METHOD=serial \
  DSMRREADER_REMOTE_DATALOGGER_SERIAL_PORT=/dev/ttyUSB0 \
  DSMRREADER_REMOTE_DATALOGGER_SERIAL_BAUDRATE=115200 \
  DSMRREADER_REMOTE_DATALOGGER_SERIAL_BYTESIZE=8 \
  DSMRREADER_REMOTE_DATALOGGER_SERIAL_PARITY=N \
  DSMRREADER_REMOTE_DATALOGGER_NETWORK_HOST=127.0.0.1 \
  DSMRREADER_REMOTE_DATALOGGER_NETWORK_PORT=23

# copy local files
COPY --from=staging /app /app

RUN echo "**** install runtime packages ****" \
  && rm -rf /var/cache/apk/* \
  && rm -rf /tmp/* \
  && apk --update add --no-cache \
  bash \
  curl \
  coreutils \
  ca-certificates \
  shadow \
  dpkg \
  jq \
  nginx \
  openssl \
  netcat-openbsd \
  postgresql16-client \
  mariadb-connector-c-dev \
  mariadb-client \
  libjpeg-turbo \
  tzdata

RUN echo "**** install s6 overlay ****" \
  && case "${TARGETARCH}/${TARGETVARIANT}" in \
  "amd64/")  S6_ARCH=x86_64 ;; \
  "arm64/")  S6_ARCH=aarch64 ;; \
  "arm/v7")  S6_ARCH=arm ;; \
  "arm/v6")  S6_ARCH=armhf ;; \
  esac \
  && wget -P /tmp https://github.com/just-containers/s6-overlay/releases/download/v"${S6_VERSION}"/s6-overlay-noarch.tar.xz \
  && wget -P /tmp https://github.com/just-containers/s6-overlay/releases/download/v"${S6_VERSION}"/s6-overlay-"${S6_ARCH}".tar.xz \
  && tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz \
  && tar -C / -Jxpf /tmp/s6-overlay-"${S6_ARCH}".tar.xz \
  && wget -P /tmp https://github.com/just-containers/s6-overlay/releases/download/v"${S6_VERSION}"/s6-overlay-symlinks-noarch.tar.xz \
  && tar -C / -Jxpf /tmp/s6-overlay-symlinks-noarch.tar.xz \
  && wget -P /tmp https://github.com/just-containers/s6-overlay/releases/download/v"${S6_VERSION}"/s6-overlay-symlinks-arch.tar.xz \
  && tar -C / -Jxpf /tmp/s6-overlay-symlinks-arch.tar.xz \
  && rm -rf /tmp/s6-overlay-*.tar.xz

RUN echo "**** install build packages ****" \
  && apk add --no-cache --virtual .build-deps gcc python3-dev musl-dev postgresql-dev build-base mariadb-dev libffi-dev jpeg-dev cargo rust \
  && echo "**** install pip packages ****" \
  && python3 -m pip install "cython<3.0.0" --no-cache-dir \
  && python3 -m pip install -r /app/dsmrreader/provisioning/requirements/base.txt --no-cache-dir \
  && python3 -m pip install psycopg2 --no-cache-dir \
  && python3 -m pip install mysqlclient --no-cache-dir \
  && python3 -m pip install tzupdate --no-cache-dir \
  && echo "**** create app user and make base folders ****" \
  && groupmod -g 1000 users \
  && useradd -u 803 -U -d /config -s /bin/false app \
  && usermod -G users,dialout,audio app \
  && mkdir -vp /app /config /defaults \
  && echo "**** copy default settings dsmr reader ****" \
  && cp -f /app/dsmrreader/provisioning/django/settings.py.template /app/dsmrreader/settings.py \
  && echo "**** cleanup package leftovers ****" \
  && apk --purge del .build-deps \
  && apk --purge del \
  && rm -rf /var/cache/apk/* \
  && rm -rf /tmp/*

RUN echo "**** configure nginx package ****" \
  && mkdir -vp /run/nginx/ \
  && mkdir -vp /etc/nginx/http.d \
  && ln -sf /dev/stdout /var/log/nginx/access.log \
  && ln -sf /dev/stderr /var/log/nginx/error.log \
  && rm -f /etc/nginx/http.d/default.conf \
  && mkdir -vp /var/www/dsmrreader/static \
  && cp -f /app/dsmrreader/provisioning/nginx/dsmr-webinterface /etc/nginx/http.d/dsmr-webinterface.conf

#---------------------------------------------------------------------------------------------------------------------------
# FINAL STEP
#---------------------------------------------------------------------------------------------------------------------------
FROM base as final

COPY rootfs /
COPY ./docker/entrypoint /

# TODO: Improve healtcheck to respond on 200 only
# TODO: Improve healtcheck so it's only valid for containers with the webinterface enabled
HEALTHCHECK --interval=15s --timeout=3s --retries=10 CMD curl -Lsf http://127.0.0.1/about -o /dev/null -w "HTTP_%{http_code}" || exit 1

WORKDIR /app

ENTRYPOINT [
