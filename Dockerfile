# syntax=docker/dockerfile:1.7

ARG PYTHON_IMAGE=python:3.14.2-slim-trixie
ARG S6_OVERLAY_VERSION=3.2.1.0

#######################################################################
# STAGING: Download Assets (Source Code & S6 Overlay)
#######################################################################
FROM --platform=$BUILDPLATFORM ${PYTHON_IMAGE} AS staging
WORKDIR /app

ARG DSMR_VERSION
ENV DSMR_VERSION="${DSMR_VERSION:-development}"
ARG S6_OVERLAY_VERSION
ARG TARGETARCH
ARG TARGETVARIANT

# Cache-busting layer
RUN echo "Using DSMR_VERSION=${DSMR_VERSION}"

RUN <<EOF
set -euo pipefail

apt-get update
apt-get install -y --no-install-recommends \
  curl ca-certificates tar gzip xz-utils
rm -rf /var/lib/apt/lists/*

# --- Download DSMR Reader ---
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

# --- Download S6 Overlay ---
case "${TARGETARCH}/${TARGETVARIANT}" in
  "amd64/")  S6_ARCH="x86_64" ;;
  "arm64/")  S6_ARCH="aarch64" ;;
  "arm/v7")  S6_ARCH="armhf" ;;
  *) echo "Unsupported TARGETARCH/TARGETVARIANT: ${TARGETARCH}/${TARGETVARIANT}" ; exit 1 ;;
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
    build-essential \
    gcc \
    g++ \
    make \
    pkg-config \
    libffi-dev \
    libjpeg-dev \
    zlib1g-dev \
    libpng-dev \
    libpq-dev \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

ENV VENV_PATH="/opt/venv"
RUN python -m venv "${VENV_PATH}"
ENV PATH="${VENV_PATH}/bin:${PATH}"

# Copy only dependency files first for better caching
COPY --from=staging /app/pyproject.toml /app/poetry.lock /app/

RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --no-cache-dir poetry && \
    poetry config virtualenvs.create false && \
    . /opt/venv/bin/activate &&poetry install --only main --no-root --no-interaction --no-ansi && \
    pip uninstall -y poetry

# Aggressive cleanup of Python packages
RUN find /opt/venv -type d -name '__pycache__' -prune -exec rm -rf {} + && \
    find /opt/venv -type d -name 'tests' -prune -exec rm -rf {} + && \
    find /opt/venv -type d -name '*.dist-info' -exec rm -rf {}/tests {} + 2>/dev/null || true && \
    find /opt/venv -type f -name '*.pyc' -delete && \
    find /opt/venv -type f -name '*.pyo' -delete && \
    find /opt/venv -type f -name '*.so*' -exec strip --strip-unneeded {} + 2>/dev/null || true

#######################################################################
# FINAL: Runtime image
#######################################################################
FROM ${PYTHON_IMAGE} AS final
WORKDIR /app
ENV DEBIAN_FRONTEND=noninteractive

ENV VENV_PATH=/opt/venv
ENV PATH="${VENV_PATH}/bin:${PATH}"
ENV PYTHONPATH=/app
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Copy compiled dependencies
COPY --from=builder /opt/venv /opt/venv

# Copy S6 overlay
COPY --from=staging /s6-dist /

ARG DSMR_VERSION=development
ENV DSMR_VERSION="${DSMR_VERSION}"
ARG DOCKER_TARGET_RELEASE=development
ENV DOCKER_TARGET_RELEASE="${DOCKER_TARGET_RELEASE}"
ARG S6_OVERLAY_VERSION
ENV S6_OVERLAY_VERSION="${S6_OVERLAY_VERSION}"

# S6 Settings
ENV S6_KEEP_ENV=1 \
    S6_CMD_WAIT_FOR_SERVICES_MAXTIME=0

# System Environment
ENV TERM=xterm \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# DSMR Reader Configuration
ENV DSMRREADER_LOGLEVEL=WARNING \
    DSMRREADER_SUPPRESS_STORAGE_SIZE_WARNINGS=true

# DJANGO Configuration
ENV DJANGO_DATABASE_ENGINE=django.db.backends.postgresql \
    DJANGO_DATABASE_NAME=dsmrreader \
    DJANGO_DATABASE_USER=dsmrreader \
    DJANGO_DATABASE_PASSWORD="" \
    DJANGO_SECRET_KEY="" \
    DJANGO_DATABASE_HOST=dsmrdb \
    DJANGO_DATABASE_PORT=5432 \
    DJANGO_DEBUG=false

# Configuration specific Configuration
ENV CONTAINER_RUN_MODE=standalone \
    CONTAINER_ENABLE_DEBUG=false \
    CONTAINER_ENABLE_NGINX_ACCESS_LOGS=false \
    CONTAINER_ENABLE_NGINX_SSL=false \
    CONTAINER_ENABLE_HTTP_AUTH=false \
    CONTAINER_ENABLE_CLIENTCERT_AUTH=false \
    CONTAINER_ENABLE_IFRAME=false \
    CONTAINER_ENABLE_VACUUM_DB_AT_STARTUP=false

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    curl \
    jq \
    nginx-light \
    openssl \
    tzdata \
    netcat-traditional \
    postgresql-client \
    passwd \
    locales \
    xz-utils \
    libcap2-bin \
    vim-tiny \
    && rm -rf /var/lib/apt/lists/*

# Aggressive system cleanup
RUN rm -rf \
    /usr/share/doc/* \
    /usr/share/man/* \
    /usr/share/locale/* \
    /usr/share/info/* \
    /var/cache/debconf/* \
    /usr/share/lintian/* \
    /usr/share/linda/* \
    /root/.cache/* \
    /tmp/* \
    /var/tmp/*

# Copy application code (do this late for better caching)
COPY --from=staging /app /app

# Copy `3 configuration
COPY rootfs /

# Set build version - spaces for outline on print
RUN { \
    printf "DSMR Reader version: %s\n" "${DSMR_VERSION}"; \
    printf "DSMR Reader Docker version: %s\n" "${DOCKER_TARGET_RELEASE}"; \
    printf "Build-date: %s\n" "$(date +%Y%m%d-%H%M)"; \
    } > /build_version

# Remove default nginx site
RUN rm -f /etc/nginx/sites-enabled/default

# Create app user with proper permissions
RUN useradd -r -u 803 -U -d /app -s /bin/false app && \
    usermod -a -G dialout,audio,uucp app && \
    mkdir -p /run/nginx/tmp /run/nginx/conf.d /run/nginx/server-snippets && \
    chown -R app:app /run/nginx && \
    chmod -R 755 /run/nginx

# Allow nginx to bind to privileged ports without root
RUN setcap 'cap_net_bind_service=+ep' /usr/sbin/nginx

# Enhanced healthcheck
HEALTHCHECK --interval=120s --timeout=5s --start-period=60s --retries=3 \
  CMD curl -fsSL http://127.0.0.1/healthcheck -o /dev/null || exit 1

ENTRYPOINT ["/init"]
