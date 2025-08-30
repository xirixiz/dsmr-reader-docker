#---------------------------------------------------------------------------------------------------------------------------
# STAGING STEP: download DSMR source
#---------------------------------------------------------------------------------------------------------------------------
FROM --platform=$BUILDPLATFORM python:3.12-alpine3.22 as staging
WORKDIR /app

ARG DSMR_VERSION
ENV DSMR_VERSION=${DSMR_VERSION:-5.11.0}

RUN apk add --no-cache curl tar \
    && echo "**** Download DSMR ****" \
    && curl -SskLf "https://github.com/dsmrreader/dsmr-reader/archive/refs/tags/v${DSMR_VERSION}.tar.gz" \
        | tar xvzf - --strip-components=1 -C /app \
    && curl -SskLf "https://raw.githubusercontent.com/dsmrreader/dsmr-reader/v${DSMR_VERSION}/dsmr_datalogger/scripts/dsmr_datalogger_api_client.py" \
        -o /app/dsmr_datalogger_api_client.py

#---------------------------------------------------------------------------------------------------------------------------
# BASE STEP: runtime image
#---------------------------------------------------------------------------------------------------------------------------
FROM python:3.12-alpine3.22 as base
WORKDIR /app

# Build arguments
ARG DSMR_VERSION
ENV DSMR_VERSION=${DSMR_VERSION}
ENV LD_LIBRARY_PATH=/usr/lib:/usr/local/lib:$LD_LIBRARY_PATH

# Algemene omgevingsvariabelen
ENV DSMR_VERSION=${DSMR_VERSION} \
    LD_LIBRARY_PATH=/usr/lib:/usr/local/lib:$LD_LIBRARY_PATH \
    PS1="$(whoami)@dsmr_reader_docker:$(pwd)\\$ " \
    TERM="xterm" \
    PIP_NO_CACHE_DIR=1 \

    # DSMR Reader-specifieke omgevingsvariabelen    
    S6_CMD_WAIT_FOR_SERVICES_MAXTIME=0 \
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

# Runtime dependencies only
RUN apk add --no-cache \
        bash curl coreutils ca-certificates shadow jq nginx \
        openssl postgresql17-client tzdata \
        s6-overlay netcat-openbsd dpkg mariadb-client musl-locales \
        libffi jpeg libjpeg-turbo libpng zlib mariadb-connector-c-dev \
    && echo "**** install build dependencies ****" \
    && apk add --no-cache --virtual .build-deps \
        gcc python3-dev musl-dev postgresql17-dev build-base rust cargo \
        libffi-dev jpeg-dev libjpeg-turbo-dev libpng-dev zlib-dev mariadb-dev \
    && echo "**** install uv ****" \
    && curl -LsSf https://astral.sh/uv/install.sh | sh \
    && ln -s /root/.local/bin/uv /usr/local/bin/uv

# Install Python dependencies directly
RUN cd /app/dsmrreader \
    && uv pip install --system --no-cache -r /app/dsmrreader/provisioning/requirements/base.txt \
    && uv pip install --system --no-cache tzupdate mysqlclient \
    && apk del .build-deps \
    && rm -rf /var/cache/apk/* /tmp/* /root/.cache \
    && find /app -name "__pycache__" -type d -exec rm -rf {} +

# Setup nginx
RUN mkdir -p /run/nginx /etc/nginx/http.d /var/www/dsmrreader/static \
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log \
    && rm -f /etc/nginx/http.d/default.conf \
    && cp /app/dsmrreader/provisioning/nginx/dsmr-webinterface /etc/nginx/http.d/dsmr-webinterface.conf    

# Create app user
RUN groupmod -g 1000 users \
    && useradd -u 803 -U -d /config -s /bin/false app \
    && usermod -G users,dialout,audio app \
    && mkdir -p /config /defaults    

# Copy settings template
RUN cp /app/dsmrreader/provisioning/django/settings.py.template /app/dsmrreader/settings.py

#---------------------------------------------------------------------------------------------------------------------------
# FINAL STEP
#---------------------------------------------------------------------------------------------------------------------------
FROM base as final
COPY rootfs /

WORKDIR /app

HEALTHCHECK --interval=15s --timeout=3s --retries=10 CMD curl -Lsf http://127.0.0.1/about -o /dev/null || exit 1
ENTRYPOINT ["/init"]