# syntax=docker/dockerfile:1.7

ARG PYTHON_IMAGE=python:3.14.2-slim-trixie
ARG S6_OVERLAY_VERSION=3.2.1.0

#######################################################################
# STAGING: Download DSMR Reader from GitHub into /app
#######################################################################
FROM --platform=$BUILDPLATFORM ${PYTHON_IMAGE} AS staging
WORKDIR /app

ARG DSMR_VERSION=development
ENV DSMR_VERSION="${DSMR_VERSION}"

RUN <<'EOF'
set -euo pipefail

apt-get update
apt-get install -y --no-install-recommends \
  curl ca-certificates tar gzip
rm -rf /var/lib/apt/lists/*

RAW_VERSION="${DSMR_VERSION#v}"

if [ "${RAW_VERSION}" = "development" ]; then
  ARCHIVE_PATH="refs/heads/development.tar.gz"
else
  ARCHIVE_PATH="refs/tags/v${RAW_VERSION}.tar.gz"
fi

URL="https://github.com/dsmrreader/dsmr-reader/archive/${ARCHIVE_PATH}"
echo "Downloading: ${URL}"

curl -fsSL "${URL}" -o /tmp/dsmr.tar.gz
tar -xzf /tmp/dsmr.tar.gz --strip-components=1 -C /app

if [ -d /app/src ]; then
  cp -a /app/src/. /app/
  rm -rf /app/src
fi

rm -f /tmp/dsmr.tar.gz
EOF

#######################################################################
# BUILDER: Poetry installs deps into a single venv
#######################################################################
FROM ${PYTHON_IMAGE} AS builder
WORKDIR /app
ENV DEBIAN_FRONTEND=noninteractive

RUN <<'EOF'
set -euo pipefail
apt-get update
apt-get install -y --no-install-recommends \
  build-essential gcc g++ make \
  python3-dev \
  rustc cargo \
  pkg-config \
  libffi-dev \
  libffi8 \
  python3-cffi \
  python3-cffi-backend \
  libjpeg-dev \
  zlib1g-dev \
  libpng-dev \
  libpq-dev \
  default-libmysqlclient-dev \
  curl ca-certificates
rm -rf /var/lib/apt/lists/*
EOF

ENV VENV_PATH=/opt/venv
RUN python -m venv "${VENV_PATH}"
ENV PATH="${VENV_PATH}/bin:${PATH}"

# Without armv6, Poetry install should be stable again
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --no-cache-dir poetry

COPY --from=staging /app/pyproject.toml /app/
COPY --from=staging /app/poetry.lock /app/
COPY --from=staging /app/dsmrreader /app/dsmrreader

RUN --mount=type=cache,target=/root/.cache/pip \
    poetry config virtualenvs.create false && \
    poetry install --only main --no-root --no-interaction --no-ansi

COPY --from=staging /app /app

RUN find /opt/venv -type d -name '__pycache__' -prune -exec rm -rf {} + && \
    find /opt/venv -type f -name '*.pyc' -delete

RUN /opt/venv/bin/python -m pip uninstall -y pip setuptools wheel || true

RUN apt-get purge -y \
    build-essential gcc g++ make \
    rustc cargo \
    pkg-config \
    python3-dev \
    libffi-dev libjpeg-dev zlib1g-dev libpng-dev \
    libpq-dev default-libmysqlclient-dev && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* /root/.cache /tmp/*

#######################################################################
# FINAL: runtime image
#######################################################################
FROM ${PYTHON_IMAGE} AS final
WORKDIR /app
ENV DEBIAN_FRONTEND=noninteractive

ENV VENV_PATH=/opt/venv
ENV PATH="${VENV_PATH}/bin:${PATH}"
ENV PYTHONPATH=/app

COPY --from=builder /opt/venv /opt/venv

ARG DSMR_VERSION=development
ENV DSMR_VERSION="${DSMR_VERSION}"

ARG DOCKER_TARGET_RELEASE=development
ENV DOCKER_TARGET_RELEASE="${DOCKER_TARGET_RELEASE}"

ARG S6_OVERLAY_VERSION
ENV S6_OVERLAY_VERSION="${S6_OVERLAY_VERSION}"

ENV PS1="\$(whoami)@dsmr_reader:\$(pwd)\\$ " \
    TERM="xterm" \
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
    DSMRREADER_OPERATION_MODE="standalone" \
    DSMRREADER_LOGLEVEL="ERROR" \
    ENABLE_NGINX_ACCESS_LOGS="false" \
    ENABLE_VACUUM_DB_ON_STARTUP="false" \
    DSMRREADER_SUPPRESS_STORAGE_SIZE_WARNINGS="true" \
    DSMRREADER_REMOTE_DATALOGGER_INPUT_METHOD="serial" \
    DSMRREADER_REMOTE_DATALOGGER_SERIAL_PORT="/dev/ttyUSB0" \
    DSMRREADER_REMOTE_DATALOGGER_SERIAL_BAUDRATE="115200" \
    DSMRREADER_REMOTE_DATALOGGER_SERIAL_BYTESIZE="8" \
    DSMRREADER_REMOTE_DATALOGGER_SERIAL_PARITY="N" \
    DSMRREADER_REMOTE_DATALOGGER_NETWORK_HOST="127.0.0.1" \
    DSMRREADER_REMOTE_DATALOGGER_NETWORK_PORT="23"

RUN <<'EOF'
set -euo pipefail

apt-get update
apt-get install -y --no-install-recommends \
  bash ca-certificates curl jq nginx openssl tzdata \
  netcat-openbsd \
  postgresql-client mariadb-client \
  passwd login \
  xz-utils

rm -rf /var/lib/apt/lists/*

ARCH="$(dpkg --print-architecture)"
case "${ARCH}" in
  amd64)  S6_ARCH="x86_64" ;;   # x86_64
  arm64)  S6_ARCH="aarch64" ;;  # ARMv8+
  armhf)  S6_ARCH="armhf" ;;    # ARMv7 (armv6 intentionally unsupported)
  *)
    echo "Unsupported architecture for s6-overlay: ${ARCH}" >&2
    exit 1
    ;;
esac

curl -fsSL -o /tmp/s6-noarch.tar.xz \
  "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz"
curl -fsSL -o /tmp/s6-arch.tar.xz \
  "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-${S6_ARCH}.tar.xz"

tar -C / -Jxpf /tmp/s6-noarch.tar.xz
tar -C / -Jxpf /tmp/s6-arch.tar.xz
rm -f /tmp/s6-*.tar.xz

rm -f /etc/nginx/sites-enabled/default || true

mkdir -p /etc/nginx/conf.d /run/nginx /var/www/dsmrreader/static

nginx -t
EOF

COPY --from=staging /app /app
COPY rootfs /

RUN set -eux; \
    mkdir -p /config /defaults; \
    useradd -u 803 -U -d /config -s /usr/sbin/nologin app; \
    usermod -a -G dialout,audio app; \
    chown -R app:app /config /defaults /var/www/dsmrreader

HEALTHCHECK \
  --interval=15s \
  --timeout=3s \
  --retries=10 \
  CMD curl -fsSL http://127.0.0.1/about -o /dev/null || exit 1

ENTRYPOINT ["/init"]
