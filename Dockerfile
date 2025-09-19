#---------------------------------------------------------------------------------------------------------------------------
# STAGING STEP
#---------------------------------------------------------------------------------------------------------------------------
FROM --platform=$BUILDPLATFORM python:3.13-alpine AS staging
WORKDIR /app

ARG DSMR_VERSION
ENV DSMR_VERSION=${DSMR_VERSION:-6.0.0}

RUN apk add --no-cache curl \
    && echo "**** Download DSMR ****" \
    && curl -SskLf "https://github.com/dsmrreader/dsmr-reader/archive/refs/tags/v${DSMR_VERSION}.tar.gz" | tar xvzf - --strip-components=1 -C /app \
    && curl -SskLf "https://raw.githubusercontent.com/dsmrreader/dsmr-reader/v${DSMR_VERSION}/dsmr_datalogger/scripts/dsmr_datalogger_api_client.py" -o /app/dsmr_datalogger_api_client.py

#---------------------------------------------------------------------------------------------------------------------------
# BASE STEP
#---------------------------------------------------------------------------------------------------------------------------
FROM python:3.13-alpine AS base

# Build arguments
ARG DSMR_VERSION
ENV DSMR_VERSION=${DSMR_VERSION:-6.0.0}
ENV LD_LIBRARY_PATH=/usr/lib:/usr/local/lib:$LD_LIBRARY_PATH

# Algemene omgevingsvariabelen
ENV PS1="$(whoami)@dsmr_reader_docker:$(pwd)\\$ " \
    TERM="xterm" \
    PIP_NO_CACHE_DIR=1 \
    S6_CMD_WAIT_FOR_SERVICES_MAXTIME=0

# Poetry / DSMR Reader-specifieke omgevingsvariabelen
ENV POETRY_VIRTUALENVS_CREATE=true \
    POETRY_VIRTUALENVS_IN_PROJECT=true \
    POETRY_VIRTUALENVS_PATH=/app/.venv \
    DJANGO_SECRET_KEY=dsmrreader \
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

# Kopieer bestanden uit staging
COPY --from=staging /app /app

# Kopieer bestanden van rootfs
COPY rootfs/app/ app/

RUN apk add --no-cache \
    bash curl coreutils ca-certificates shadow jq nginx \
    s6-overlay openssl postgresql17-client tzdata \
    netcat-openbsd dpkg mariadb-client \
    libffi jpeg libjpeg-turbo libpng zlib mariadb-connector-c-dev \
    && echo "**** install build dependencies ****" \
    && apk add --no-cache --virtual .build-deps \
        gcc python3-dev musl-dev postgresql17-dev build-base rust cargo \
        libffi-dev jpeg-dev libjpeg-turbo-dev libpng-dev zlib-dev mariadb-dev

RUN echo "**** install python packages ****" \
    && python3 -m pip install --no-cache-dir --upgrade pip \
    && pip install poetry \
    && poetry install --directory=/app --without dev --no-root \
    && poetry add --directory=/app tzupdate mysqlclient

RUN echo "**** cleanup ****" \
    && apk del .build-deps \
    && rm -rf /var/cache/apk/* /tmp/* /root/.cache

# Setup nginx (vhost in rootfs/etc/nginx/http.d/dsmr-webinterface)
RUN mkdir -p /run/nginx /etc/nginx/http.d /var/www/dsmrreader/static \
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log \
    && rm -f /etc/nginx/http.d/default.conf

# Create app user
RUN groupmod -g 1000 users \
    && useradd -u 803 -U -d /config -s /bin/false app \
    && usermod -G users,dialout,audio app \
    && mkdir -p /config /defaults

#---------------------------------------------------------------------------------------------------------------------------
# FINAL STEP
#---------------------------------------------------------------------------------------------------------------------------
FROM base AS final

COPY rootfs /

HEALTHCHECK --interval=15s --timeout=3s --retries=10 CMD curl -Lsf http://127.0.0.1/about -o /dev/null || exit 1

WORKDIR /app
ENTRYPOINT ["/init"]
