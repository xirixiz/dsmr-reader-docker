ARG BASE
FROM ${BASE}

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
    VACUUM_DB_ON_STARTUP=false \ 
    SD_LOGLEVEL=info \
    SD_USER=root \
    SD_GROUP=root

COPY ./dsmr/ /dsmr

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

RUN mkdir -p /var/log/supervisor/ \
    && touch /var/log/supervisor/dsmr_datalogger.log \
    && touch /var/log/supervisor/dsmr_remote_datalogger.log \
    && touch /var/log/supervisor/dsmr_backend.log \
    && touch /var/log/supervisor/dsmr_webinterface.log \
    && ln -sf /dev/stdout /var/log/supervisor/dsmr_datalogger.log \
    && ln -sf /dev/stdout /var/log/supervisor/dsmr_remote_datalogger.log \
    && ln -sf /dev/stdout /var/log/supervisor/dsmr_backend.log \
    && ln -sf /dev/stdout /var/log/supervisor/dsmr_webinterface.log \
    && touch /tmp/supervisord.log \
    && ln -sf /dev/stdout /tmp/supervisord.log

RUN mkdir -p /run/nginx/ \
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log \
    && rm -f /etc/nginx/conf.d/default.conf \
    && mkdir -p /var/www/dsmrreader/static \
    && cp -f /dsmr/dsmrreader/provisioning/nginx/dsmr-webinterface /etc/nginx/conf.d/dsmr-webinterface.conf

COPY ./app /app
RUN chmod u+x /app/*.sh

RUN curl -Ssl 'https://api.github.com/repos/dsmrreader/dsmr-reader/releases/latest' | jq -r .tag_name > /app/DSMR_RELEASE

COPY ./config/supervisord.ini /etc/supervisor.d/supervisord.ini

EXPOSE 80 443

WORKDIR /dsmr

CMD ["/bin/bash", "-c", "/app/run.sh"]
