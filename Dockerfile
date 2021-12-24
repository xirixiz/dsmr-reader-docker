ARG BASE_IMAGE
FROM ${BASE_IMAGE:-amd64/python:3-alpine3.13}

ARG QEMU_ARCH
ARG S6_ARCH
ARG DSMR_VERSION

ENV QEMU_ARCH=${QEMU_ARCH:-x86_64}
ENV S6_ARCH=${S6_ARCH:-amd64}
ENV S6_KEEP_ENV=1
ENV DSMR_VERSION=${DSMR_VERSION:-4.19.0}

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
    DATALOGGER_MODE=standalone \
    VACUUM_DB_ON_STARTUP=false

COPY /tmp/qemu/qemu-${QEMU_ARCH}-static /usr/bin/qemu-${QEMU_ARCH}-static
COPY /tmp/s6-${S6_ARCH}/ /
COPY /tmp/dsmr/ /dsmr

COPY app /app
COPY rootfs /

RUN apk --update add --no-cache \
    bash \
    dpkg \
    curl \
    nginx \
    openssl \
    netcat-openbsd \
    postgresql-client \
    mariadb-connector-c-dev \
    mariadb-client \
    tzdata

RUN cp -f /dsmr/dsmrreader/provisioning/django/settings.py.template /dsmr/dsmrreader/settings.py

RUN apk add --no-cache --virtual .build-deps gcc python3-dev musl-dev postgresql-dev build-base mariadb-dev libressl-dev libffi-dev cargo rust \
    && python3 -m pip install --upgrade pip \
    && python3 -m pip install -r /dsmr/dsmrreader/provisioning/requirements/base.txt --no-cache-dir \
    && python3 -m pip install psycopg2 --no-cache-dir \
    && python3 -m pip install mysqlclient --no-cache-dir \
    && python3 -m pip install tzupdate --no-cache-dir \
    && mkdir -p /app /config /defaults \
    && apk --purge del .build-deps \
    && apk --purge del \
    && rm -rf /var/cache/apk/* \
    && rm -rf /tmp/*

RUN mkdir -p /run/nginx/ \
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log \
    && rm -f /etc/nginx/conf.d/default.conf \
    && mkdir -p /var/www/dsmrreader/static \
    && cp -f /dsmr/dsmrreader/provisioning/nginx/dsmr-webinterface /etc/nginx/conf.d/dsmr-webinterface.conf

HEALTHCHECK --interval=5s --timeout=3s --retries=10 CMD curl -sf http://localhost/about -o /dev/null -w "%{http_code}\n" || exit 1

WORKDIR /dsmr

ENTRYPOINT ["/init"]