#######################################################################
# STAGING: Download DSMR Reader and extract repo directly into /app
#######################################################################
FROM --platform=$BUILDPLATFORM python:3.13-alpine AS staging

WORKDIR /app

ARG DSMR_VERSION=development
ENV DSMR_VERSION="${DSMR_VERSION}"

RUN <<EOF
set -euo pipefail

apk add --no-cache curl

# Normalize version: strip leading 'v'
RAW_VERSION="${DSMR_VERSION#v}"

if [ "${RAW_VERSION}" = "development" ]; then
  ARCHIVE_PATH="refs/heads/development.tar.gz"
else
  ARCHIVE_PATH="refs/tags/v${RAW_VERSION}.tar.gz"
fi

URL="https://github.com/dsmrreader/dsmr-reader/archive/${ARCHIVE_PATH}"
echo "Downloading: ${URL}"

curl -SsfL "${URL}" -o /tmp/dsmr.tar.gz

tar -xzf /tmp/dsmr.tar.gz --strip-components=1 -C /app
cp -a /app/src/. /app/
rm -rf /app/src

rm -f /tmp/dsmr.tar.gz
EOF

#######################################################################
# BUILDER: install DSMR Python deps into /install
#######################################################################
FROM python:3.13-alpine AS builder

WORKDIR /app

RUN --mount=type=cache,target=/var/cache/apk \
    apk add --no-cache --virtual .build-deps \
      build-base \
      gcc \
      musl-dev \
      python3-dev \
      rust \
      cargo \
      libffi-dev \
      jpeg-dev \
      libjpeg-turbo-dev \
      libpng-dev \
      zlib-dev \
      postgresql17-dev \
      mariadb-dev \
      mariadb-connector-c-dev

COPY --from=staging /app /app

ENV PYTHONDONTWRITEBYTECODE=1 \
    PIP_ROOT_USER_ACTION=ignore \
    PYTHONUNBUFFERED=1 \
    PIP_PREFER_BINARY=1 \
    PIP_NO_CACHE_DIR=1

# Create an isolated Poetry venv so it doesn't pollute system site-packages
RUN python -m venv /poetry-venv

# Install Poetry + export plugin in that venv
RUN --mount=type=cache,target=/root/.cache/pip \
    /poetry-venv/bin/pip install --no-cache-dir \
      poetry \
      poetry-plugin-export

# Use Poetry (in its venv) to export project dependencies
RUN /poetry-venv/bin/poetry export \
      -f requirements.txt \
      --without-hashes \
      -o /tmp/requirements.txt

# Install runtime deps into /install using the *system* pip
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --no-cache-dir --prefix=/install -r /tmp/requirements.txt && \
    pip install --no-cache-dir --prefix=/install \
      psycopg \
      mysqlclient \
      tzupdate

# Clean up build deps and temporary stuff
RUN apk del .build-deps && \
    rm -f /tmp/requirements.txt && \
    rm -rf /poetry-venv && \
    rm -rf /root/.cache /tmp/* /var/cache/apk/*


#######################################################################
# FINAL: runtime image
#######################################################################
FROM python:3.13-alpine AS final

ARG DSMR_VERSION=development
ENV DSMR_VERSION="${DSMR_VERSION}"

ARG DOCKER_TARGET_RELEASE=2025.1000
ENV DOCKER_TARGET_RELEASE=${DOCKER_TARGET_RELEASE}

WORKDIR /app

ENV LD_LIBRARY_PATH="/usr/lib:/usr/local/lib:${LD_LIBRARY_PATH:-}" \
    PS1="$(whoami)@dsmr_reader:$(pwd)\\$ " \
    TERM="xterm" \
    PIP_NO_CACHE_DIR=1 \
    S6_CMD_WAIT_FOR_SERVICES_MAXTIME=0 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

ENV DJANGO_SECRET_KEY="dsmrreader" \
    DJANGO_DATABASE_ENGINE="django.db.backends.postgresql" \
    DJANGO_DATABASE_NAME="dsmrreader" \
    DJANGO_DATABASE_USER="dsmrreader" \
    DJANGO_DATABASE_PASSWORD="dsmrreader" \
    DJANGO_DATABASE_HOST="dsmrdb" \
    DJANGO_DATABASE_PORT="5432" \
    DSMRREADER_ADMIN_USER="admin" \
    DSMRREADER_ADMIN_PASSWORD="admin" \
    DSMRREADER_OPERATION_MODE="standalone" \
    DISABLE_NGINX_ACCESS_LOGS="true" \
    VACUUM_DB_ON_STARTUP="false" \
    DSMRREADER_SUPPRESS_STORAGE_SIZE_WARNINGS="True" \
    DSMRREADER_REMOTE_DATALOGGER_INPUT_METHOD="serial" \
    DSMRREADER_REMOTE_DATALOGGER_SERIAL_PORT="/dev/ttyUSB0" \
    DSMRREADER_REMOTE_DATALOGGER_SERIAL_BAUDRATE="115200" \
    DSMRREADER_REMOTE_DATALOGGER_SERIAL_BYTESIZE="8" \
    DSMRREADER_REMOTE_DATALOGGER_SERIAL_PARITY="N" \
    DSMRREADER_REMOTE_DATALOGGER_NETWORK_HOST="127.0.0.1" \
    DSMRREADER_REMOTE_DATALOGGER_NETWORK_PORT="23"

RUN --mount=type=cache,target=/var/cache/apk \
    apk add --no-cache \
      bash \
      ca-certificates \
      coreutils \
      curl \
      jq \
      nginx \
      openssl \
      s6-overlay \
      tzdata \
      postgresql17-client \
      mariadb-client \
      netcat-openbsd \
      dpkg \
      shadow \
      libffi \
      jpeg \
      libjpeg-turbo \
      libpng \
      zlib \
      mariadb-connector-c

COPY --from=builder /install /usr/local
COPY --from=staging /app /app
COPY rootfs /

RUN set -eux; \
    mkdir -p /run/nginx /etc/nginx/http.d /var/www/dsmrreader/static; \
    rm -f /etc/nginx/http.d/*.conf

RUN set -eux; \
    groupmod -g 1000 users; \
    useradd -u 803 -U -d /config -s /sbin/nologin app; \
    usermod -G users,dialout,audio app; \
    mkdir -p /config /defaults; \
    chown -R app:app /config /defaults /var/www/dsmrreader

HEALTHCHECK \
  --interval=15s \
  --timeout=3s \
  --retries=10 \
  CMD curl -Lsf http://127.0.0.1/about -o /dev/null || exit 1

ENTRYPOINT ["/init"]
