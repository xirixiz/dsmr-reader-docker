# syntax=docker/dockerfile:1.7

ARG PYTHON_IMAGE=python:3.14.2-slim-trixie
ARG S6_OVERLAY_VERSION=3.2.1.0

#######################################################################
# STAGING: Download Assets (Source Code & S6 Overlay)
#######################################################################
FROM --platform=$BUILDPLATFORM ${PYTHON_IMAGE} AS staging
WORKDIR /app

ARG DSMR_VERSION=development
ARG S6_OVERLAY_VERSION
ENV DSMR_VERSION="${DSMR_VERSION}"

RUN <<'EOF'
set -euo pipefail

apt-get update
apt-get install -y --no-install-recommends \
  curl ca-certificates tar gzip xz-utils
rm -rf /var/lib/apt/lists/*

# --- 1. Download DSMR Reader ---
RAW_VERSION="${DSMR_VERSION#v}"
if [ "${RAW_VERSION}" = "development" ]; then
  ARCHIVE_PATH="refs/heads/development.tar.gz"
else
  ARCHIVE_PATH="refs/tags/v${RAW_VERSION}.tar.gz"
fi

URL="https://github.com/dsmrreader/dsmr-reader/archive/${ARCHIVE_PATH}"
echo "Downloading Source: ${URL}"

curl -fsSL "${URL}" -o /tmp/dsmr.tar.gz
tar -xzf /tmp/dsmr.tar.gz --strip-components=1 -C /app

if [ -d /app/src ]; then
  cp -a /app/src/. /app/
  rm -rf /app/src
fi

# --- 2. Download S6 Overlay ---
ARCH="$(dpkg --print-architecture)"
case "${ARCH}" in
  amd64)  S6_ARCH="x86_64" ;;   # x86_64
  arm64)  S6_ARCH="aarch64" ;;  # ARMv8+
  armhf)  S6_ARCH="armhf" ;;    # ARMv7
  *) echo "Unsupported arch: ${ARCH}"; exit 1 ;;
esac

echo "Downloading S6 Overlay for ${S6_ARCH}"
curl -fsSL -o /tmp/s6-noarch.tar.xz \
  "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz"
curl -fsSL -o /tmp/s6-arch.tar.xz \
  "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-${S6_ARCH}.tar.xz"

# Prepare S6 folder
mkdir -p /s6-dist
tar -C /s6-dist -Jxpf /tmp/s6-noarch.tar.xz
tar -C /s6-dist -Jxpf /tmp/s6-arch.tar.xz
EOF

#######################################################################
# BUILDER: Compile dependencies
#######################################################################
FROM ${PYTHON_IMAGE} AS builder
WORKDIR /app
ENV DEBIAN_FRONTEND=noninteractive
ENV PIP_DISABLE_PIP_VERSION_CHECK=1
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential gcc g++ make \
    pkg-config \
    libffi-dev \
    curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

ENV VENV_PATH="/opt/venv"
RUN python -m venv "${VENV_PATH}"
ENV PATH="${VENV_PATH}/bin:${PATH}"

COPY --from=staging /app/pyproject.toml /app/poetry.lock /app/

RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --no-cache-dir poetry && \
    poetry config virtualenvs.create false && \
    . /opt/venv/bin/activate &&poetry install --only main --no-root --no-interaction --no-ansi && \
    pip uninstall -y poetry

RUN find /opt/venv -type d -name '__pycache__' -prune -exec rm -rf {} + && \
    find /opt/venv -type f -name '*.pyc' -delete

#######################################################################
# FINAL: Runtime image
#######################################################################
FROM ${PYTHON_IMAGE} AS final
WORKDIR /app
ENV DEBIAN_FRONTEND=noninteractive

ENV VENV_PATH=/opt/venv
ENV PATH="${VENV_PATH}/bin:${PATH}"
ENV PYTHONPATH=/app

COPY --from=builder /opt/venv /opt/venv
COPY --from=staging /s6-dist /
COPY --from=staging /app /app

RUN find /opt/venv -name "tests" -type d -exec rm -rf {} + \
    && find /opt/venv -name "*.pyc" -delete \
    && rm -rf /opt/venv/lib/python*/site-packages/*-info/tests \
    && rm -rf /root/.cache/pip

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
    PYTHONUNBUFFERED=1 \
    DJANGO_DATABASE_ENGINE="django.db.backends.postgresql" \
    DJANGO_DATABASE_NAME="dsmrreader" \
    DJANGO_DATABASE_USER="dsmrreader" \
    DJANGO_DATABASE_PASSWORD="dsmrreader" \
    DJANGO_SECRET_KEY="dsmrreader" \
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

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash ca-certificates curl jq nginx openssl tzdata \
    netcat-openbsd \
    postgresql-client \
    passwd \
    locales \
    xz-utils \
    libcap2-bin \
    vim-tiny \
    && rm -rf /var/lib/apt/lists/*

RUN rm -rf /usr/share/doc/* /usr/share/man/* /usr/share/locale/*

RUN find /opt/venv -name '*.so' -exec strip --strip-unneeded {} \; || true \
  && rm -rf /root/.cache/pip /tmp/* /var/tmp/* \
  && rm -rf /usr/share/doc/* /usr/share/man/* /usr/share/locale/*

COPY rootfs /

RUN rm -f /etc/nginx/sites-enabled/default || true

RUN useradd -r -u 803 -U -d /app -s /usr/sbin/nologin app && \
    usermod -a -G dialout,audio app && \
    mkdir -p /run/nginx/tmp && chown -R 803:803 /run/nginx && chmod -R 755 /run/nginx

RUN setcap 'cap_net_bind_service=+ep' /usr/sbin/nginx

HEALTHCHECK --interval=15s --timeout=3s --retries=10 \
  CMD curl -fsSL http://127.0.0.1/healthcheck -o /dev/null || exit 1

ENTRYPOINT ["/init"]
