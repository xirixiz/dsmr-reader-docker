ARG BASE
FROM ${BASE}

ENV DJANGO_SECRET_KEY dsmrreader
ENV DJANGO_DATABASE_ENGINE django.db.backends.postgresql

ENV DSMRREADER_SUPPRESS_STORAGE_SIZE_WARNINGS True

ENV DJANGO_DATABASE_NAME dsmrreader
ENV DJANGO_DATABASE_USER dsmrreader
ENV DJANGO_DATABASE_PASSWORD dsmrreader

ENV DJANGO_DATABASE_HOST dsmrdb
ENV DJANGO_DATABASE_PORT 5432

ENV DSMRREADER_ADMIN_USER admin
ENV DSMRREADER_ADMIN_PASSWORD admin

ENV DATALOGGER_MODE standalone
ENV VACUUM_DB_ON_STARTUP true

ENV SD_LOGLEVEL info
ENV SD_USER root
ENV SD_GROUP root

COPY ./dsmr/ /dsmr

RUN apk --update add --no-cache \
    bash \
    curl \
    nginx \
    openssl \
    netcat-openbsd \
    postgresql-client \
    mariadb-connector-c-dev \
    mariadb-client \
    tzdata \
    jq \
    supervisor

RUN cp -f /dsmr/dsmrreader/provisioning/django/settings.py.template /dsmr/dsmrreader/settings.py

RUN apk add --no-cache --virtual .build-deps gcc python3-dev musl-dev postgresql-dev build-base mariadb-dev libressl-dev libffi-dev cargo rust \
    && python3 -m pip install -r /dsmr/dsmrreader/provisioning/requirements/base.txt --no-cache-dir \
    && python3 -m pip install psycopg2 --no-cache-dir \
    && python3 -m pip install mysqlclient --no-cache-dir \
    && apk --purge del .build-deps \
    && rm -rf /var/cache/apk/* \
    && rm -rf /tmp/*

RUN mkdir -p /run/nginx/ \
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log \
    && rm -f /etc/nginx/conf.d/default.conf \
    && mkdir -p /var/www/dsmrreader/static \
    && cp -f /dsmr/dsmrreader/provisioning/nginx/dsmr-webinterface /etc/nginx/conf.d/dsmr-webinterface.conf

RUN curl -Ssl 'https://api.github.com/repos/dsmrreader/dsmr-reader/releases/latest' | jq -r .tag_name > /dsmr/DSMR_RELEASE

COPY ./app /app
RUN chmod u+x /app/*.sh

COPY ./config/supervisord.ini /etc/supervisor.d/supervisord.ini

EXPOSE 80 443

WORKDIR /dsmr

CMD ["/bin/bash", "-c", "/app/run.sh"]
