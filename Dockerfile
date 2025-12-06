# syntax=docker/dockerfile:1.7

FROM --platform=$BUILDPLATFORM python:3.13-alpine AS staging
WORKDIR /app

ARG DSMR_VERSION=development
ENV DSMR_VERSION=${DSMR_VERSION}

RUN echo "**** Download DSMR (version: ${DSMR_VERSION}) ****" \
    && apk add --no-cache curl \
    \
    # Select correct GitHub ref
    && if [ "${DSMR_VERSION}" = "development" ] ; then \
         ARCHIVE_PATH="refs/heads/${DSMR_VERSION}.tar.gz" ; \
         ROOT_DIR="dsmr-reader-${DSMR_VERSION}" ; \
       else \
         ARCHIVE_PATH="refs/tags/v${DSMR_VERSION}.tar.gz" ; \
         ROOT_DIR="dsmr-reader-${DSMR_VERSION}" ; \
       fi \
    \
    # Download archive
    && curl -SskLf "https://github.com/dsmrreader/dsmr-reader/archive/${ARCHIVE_PATH}" \
         -o /dsmrreader.download.tar.gz \
    \
    # Extract only src/*
    && tar xvzf /dsmrreader.download.tar.gz \
         --strip-components=2 \
         "${ROOT_DIR}/src/" \
         -C /app \
    \
    # Also copy datalogger API client
    && cp /app/dsmr_datalogger/scripts/dsmr_datalogger_api_client.py /app/dsmr_datalogger_api_client.py \
    \
    && rm /dsmrreader.download.tar.gz

#---------------------------------------------------------------------------------------------------------------------------
# BUILDER: export deps via Poetry, install to /install
#---------------------------------------------------------------------------------------------------------------------------
FROM python:3.13-alpine AS builder
WORKDIR /app

RUN --mount=type=cache,target=/var/cache/apk \
    apk add --no-cache --virtual .build-deps \
      build-base gcc musl-dev python3-dev rust cargo \
      libffi-dev jpeg-dev libjpeg-turbo-dev libpng-dev zlib-dev \
      postgresql17-dev mariadb-dev mariadb-connector-c \
      curl git

COPY --from=staging /app /app

ENV PIP_PREFER_BINARY=1
ENV PIP_NO_CACHE_DIR=1

RUN python -m pip install --upgrade pip setuptools wheel \
 && pip install --no-cache-dir poetry poetry-plugin-export \
 && POETRY_VIRTUALENVS_CREATE=false POETRY_NO_INTERACTION=1 \
    poetry lock --directory /app \
 && POETRY_VIRTUALENVS_CREATE=false POETRY_NO_INTERACTION=1 \
    poetry export --directory /app --without dev -f requirements.txt -o /deps.txt \
 && pip install --no-cache-dir --prefix=/install -r /deps.txt \
 && pip install --no-cache-dir --prefix=/install psycopg mysqlclient tzupdate

# Trim garbage
RUN set -eux; \
    find /install -type d -name '__pycache__' -prune -exec rm -rf {} +; \
    find /install -type d -name 'tests' -prune -exec rm -rf {} + || true; \
    find /install -type f -name '*.pyc' -delete; \
    find /install -type f -name '*.pyo' -delete; \
    find /install -type f -name '*.a' -delete; \
    find /install -type f -name '*.la' -delete

RUN apk del .build-deps && rm -rf /root/.cache /tmp/* /var/cache/apk/*

#---------------------------------------------------------------------------------------------------------------------------
# FINAL: runtime image with only what we need
#---------------------------------------------------------------------------------------------------------------------------
FROM python:3.13-alpine AS final
WORKDIR /app

ENV LD_LIBRARY_PATH="/usr/lib:/usr/local/lib:${LD_LIBRARY_PATH:-}" \
    PS1="$(whoami)@dsmr_reader_docker:$(pwd)\\$ " \
    TERM="xterm" \
    PIP_NO_CACHE_DIR=1 \
    S6_CMD_WAIT_FOR_SERVICES_MAXTIME=0 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

ENV DJANGO_SECRET_KEY=dsmrreader \
    DJANGO_DATABASE_ENGINE=django.db.backends.postgresql \
    DJANGO_DATABASE_NAME=dsmrreader \
    DJANGO_DATABASE_USER=dsmrreader \
    DJANGO_DATABASE_PASSWORD=dsmrreader \
    DJANGO_DATABASE_HOST=dsmrdb \
    DJANGO_DATABASE_PORT=5432 \
    DSMRREADER_ADMIN_USER=admin \
    DSMRREADER_ADMIN_PASSWORD=admin \
    DSMRREADER_OPERATION_MODE=standalone \
    VACUUM_DB_ON_STARTUP=false \
    DSMRREADER_SUPPRESS_STORAGE_SIZE_WARNINGS=True \
    DSMRREADER_REMOTE_DATALOGGER_INPUT_METHOD=serial \
    DSMRREADER_REMOTE_DATALOGGER_SERIAL_PORT=/dev/ttyUSB0 \
    DSMRREADER_REMOTE_DATALOGGER_SERIAL_BAUDRATE=115200 \
    DSMRREADER_REMOTE_DATALOGGER_SERIAL_BYTESIZE=8 \
    DSMRREADER_REMOTE_DATALOGGER_SERIAL_PARITY=N \
    DSMRREADER_REMOTE_DATALOGGER_NETWORK_HOST=127.0.0.1 \
    DSMRREADER_REMOTE_DATALOGGER_NETWORK_PORT=23

RUN --mount=type=cache,target=/var/cache/apk \
    apk add --no-cache \
      bash ca-certificates coreutils curl jq nginx openssl s6-overlay tzdata \
      postgresql17-client mariadb-client netcat-openbsd dpkg shadow \
      libffi jpeg libjpeg-turbo libpng zlib mariadb-connector-c

COPY --from=builder /install /usr/local
COPY --from=staging /app /app
COPY rootfs /

RUN set -eux; \
    mkdir -p /run/nginx /etc/nginx/http.d /var/www/dsmrreader/static; \
    ln -sf /dev/stdout /var/log/nginx/access.log; \
    ln -sf /dev/stderr /var/log/nginx/error.log; \
    rm -f /etc/nginx/http.d/default.conf

RUN set -eux; \
    groupmod -g 1000 users; \
    useradd -u 803 -U -d /config -s /bin/false app; \
    usermod -G users,dialout,audio app; \
    mkdir -p /config /defaults; \
    chown -R app:app /config /defaults

HEALTHCHECK --interval=15s --timeout=3s --retries=10 CMD curl -Lsf http://127.0.0.1/about -o /dev/null || exit 1
ENTRYPOINT ["/init"]
