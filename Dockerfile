# syntax=docker/dockerfile:1.7

#---------------------------------------------------------------------------------------------------------------------------
# STAGING: fetch DSMR source and extract requirements
#---------------------------------------------------------------------------------------------------------------------------
FROM --platform=$BUILDPLATFORM python:3.12-alpine3.22 AS staging
WORKDIR /app

ARG DSMR_VERSION=5.11.0
ENV DSMR_VERSION=${DSMR_VERSION}

RUN set -eux; \
    apk add --no-cache curl tar; \
    echo "**** Download DSMR ****"; \
    curl -SsfL "https://github.com/dsmrreader/dsmr-reader/archive/refs/tags/v${DSMR_VERSION}.tar.gz" \
      | tar xz --strip-components=1 -C /app; \
    curl -SsfL "https://raw.githubusercontent.com/dsmrreader/dsmr-reader/v${DSMR_VERSION}/dsmr_datalogger/scripts/dsmr_datalogger_api_client.py" \
      -o /app/dsmr_datalogger_api_client.py; \
    mkdir -p /deps && cp /app/dsmrreader/provisioning/requirements/base.txt /deps/requirements.txt

#---------------------------------------------------------------------------------------------------------------------------
# BUILDER: install build deps & Python packages into a staging prefix
#---------------------------------------------------------------------------------------------------------------------------
FROM python:3.12-alpine3.22 AS builder
WORKDIR /app

RUN --mount=type=cache,target=/var/cache/apk \
    apk add --no-cache \
      gcc python3-dev musl-dev build-base rust cargo libffi-dev \
      jpeg-dev libjpeg-turbo-dev libpng-dev zlib-dev \
      postgresql17-dev mariadb-connector-c-dev mariadb-dev

COPY --from=staging /deps/requirements.txt /deps/requirements.txt
COPY --from=staging /app /app

ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --no-cache-dir --prefix=/install "setuptools<81" && \
    pip install --no-cache-dir --prefix=/install -r /deps/requirements.txt && \
    pip install --no-cache-dir --prefix=/install psycopg mysqlclient tzupdate && \
    python - <<'PY'
import compileall, sys
compileall.compile_path(quiet=1)
PY

#---------------------------------------------------------------------------------------------------------------------------
# FINAL: runtime image with DB CLIs, nginx, s6, and copied site-packages
#---------------------------------------------------------------------------------------------------------------------------
FROM python:3.12-alpine3.22 AS final
WORKDIR /app

ARG DSMR_VERSION
ENV DSMR_VERSION=${DSMR_VERSION}

# General envs
ENV PS1="$(whoami)@dsmr_reader_docker:$(pwd)\\$ " \
    TERM="xterm" \
    PIP_NO_CACHE_DIR=1 \
    S6_CMD_WAIT_FOR_SERVICES_MAXTIME=0 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    # Filter noisy warnings only (Python 3.12 temporarily)
    PYTHONWARNINGS="ignore:pkg_resources is deprecated:UserWarning,ignore:invalid escape sequence:SyntaxWarning"

# Runtime deps incl. DB CLIs
RUN --mount=type=cache,target=/var/cache/apk \
    apk add --no-cache \
      bash curl coreutils ca-certificates shadow jq nginx openssl tzdata \
      s6-overlay netcat-openbsd \
      libffi jpeg libjpeg-turbo libpng zlib \
      postgresql17-client mariadb-client mariadb-connector-c

# Copy Python deps from builder
COPY --from=builder /install /usr/local

# Bring in the app
COPY --from=staging /app /app

# Nginx setup
RUN set -eux; \
    mkdir -p /run/nginx /etc/nginx/http.d /var/www/dsmrreader/static; \
    ln -sf /dev/stdout /var/log/nginx/access.log; \
    ln -sf /dev/stderr /var/log/nginx/error.log; \
    rm -f /etc/nginx/http.d/default.conf; \
    cp /app/dsmrreader/provisioning/nginx/dsmr-webinterface /etc/nginx/http.d/dsmr-webinterface.conf

# App user
RUN set -eux; \
    groupmod -g 1000 users; \
    useradd -u 803 -U -d /config -s /sbin/nologin app; \
    usermod -G users,dialout,audio app; \
    mkdir -p /config /defaults; \
    chown -R app:app /config /defaults /var/www/dsmrreader

# Settings template
RUN cp /app/dsmrreader/provisioning/django/settings.py.template /app/dsmrreader/settings.py

# DSMR envs (override secrets at runtime!)
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

# Healthcheck
HEALTHCHECK --interval=15s --timeout=5s --retries=5 CMD curl -fsSL http://127.0.0.1/about -o /dev/null || exit 1

COPY rootfs /

ENTRYPOINT ["/init"]
