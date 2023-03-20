FROM --platform=$BUILDPLATFORM python:3-alpine3.17 as staging
WORKDIR /app

ARG DSMR_VERSION
ENV DSMR_VERSION=${DSMR_VERSION:-5.0.0}

RUN echo "**** Download DSMR ****" \
  && apk add --no-cache curl \
  && curl -SskLf "https://github.com/dsmrreader/dsmr-reader/archive/refs/tags/v${DSMR_VERSION}.tar.gz" | tar xvzf - --strip-components=1 -C /app \
  && curl -SskLf "https://raw.githubusercontent.com/dsmrreader/dsmr-reader/v5/dsmr_datalogger/scripts/dsmr_datalogger_api_client.py" -o /app/dsmr_datalogger_api_client.py

FROM python:3-alpine3.17

ARG TARGETARCH
ARG TARGETVARIANT

ARG QEMU_ARCH
ARG S6_VERSION="2.2.0.3"
ARG DOCKER_TARGET_RELEASE
ARG DSMR_VERSION

ENV PS1="$(whoami)@dsmr_reader_docker:$(pwd)\\$ " \
  TERM="xterm"

ENV QEMU_ARCH=${QEMU_ARCH:-x86_64} \
  S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
  DSMR_VERSION=${DSMR_VERSION} \
  DOCKER_TARGET_RELEASE=${DOCKER_TARGET_RELEASE}

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
COPY rootfs /

RUN echo "**** install runtime packages ****" \
  && rm -rf /var/cache/apk/* \
  && rm -rf /tmp/* \
  && apk --update add --no-cache \
  bash \
  coreutils \
  curl \
  ca-certificates \
  shadow \
  dpkg \
  curl \
  jq \
  nginx \
  openssl \
  netcat-openbsd \
  postgresql-client \
  mariadb-connector-c-dev \
  mariadb-client \
  libjpeg-turbo \
  tzdata

RUN echo "**** install s6 overlay ****" \
  &&  case "${TARGETARCH}/${TARGETVARIANT}" in \
  "amd64/")  S6_ARCH=amd64  ;; \
  "arm64/")  S6_ARCH=aarch64  ;; \
  "arm/v7")  S6_ARCH=arm  ;; \
  "arm/v6")  S6_ARCH=armhf  ;; \
  esac \
  && curl "https://github.com/just-containers/s6-overlay/releases/download/v${S6_VERSION}/s6-overlay-${S6_ARCH}.tar.gz" -L -s --output /tmp/s6-overlay-${S6_ARCH}.tar.gz \
  && tar -C / -xf /tmp/s6-overlay-${S6_ARCH}.tar.gz

RUN echo "**** install build packages ****" \
  && apk add --no-cache --virtual .build-deps gcc python3-dev musl-dev postgresql-dev build-base mariadb-dev libffi-dev jpeg-dev cargo rust \
  && echo "**** install pip packages ****" \
  && python3 -m pip install --upgrade pip \
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
  && mkdir -vp /etc/nginx/conf.d \
  && ln -sf /dev/stdout /var/log/nginx/access.log \
  && ln -sf /dev/stderr /var/log/nginx/error.log \
  && rm -f /etc/nginx/http.d/default.conf \
  && mkdir -vp /var/www/dsmrreader/static \
  && cp -f /app/dsmrreader/provisioning/nginx/dsmr-webinterface /etc/nginx/http.d/dsmr-webinterface.conf

# TODO: Improve healtcheck to respond on 200 only
# TODO: Improve healtcheck so it's only valid for containers with the webinterface enabled
HEALTHCHECK --interval=15s --timeout=3s --retries=10 CMD curl -Lsf http://127.0.0.1/about -o /dev/null -w "HTTP_%{http_code}" || exit 1

WORKDIR /app

ENTRYPOINT ["/init"]
