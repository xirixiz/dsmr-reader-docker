ARG BASE
FROM ${BASE}

ENV SECRET_KEY dsmrreader
ENV DB_ENGINE django.db.backends.postgresql

ENV DB_NAME dsmrreader
ENV DB_USER dsmrreader
ENV DB_PASS dsmrreader

ENV DB_HOST dsmrdb
ENV DB_PORT 5432

ENV DSMR_USER admin
ENV DSMR_PASSWORD admin

ENV DATALOGGER_MODE standalone

ENV SD_LOGLEVEL info
ENV SD_USER root
ENV SD_GROUP root

COPY ./dsmr/ /dsmr

RUN apk --update add --no-cache \
    bash \
    curl \
    nginx \
    openssl \
    postgresql-client \
    tzdata \
    jq \
    supervisor

RUN cp -f /dsmr/dsmrreader/provisioning/django/settings.py.template /dsmr/dsmrreader/settings.py

RUN apk add --virtual .build-deps gcc python3-dev musl-dev postgresql-dev \
    && python3 -m pip install -r /dsmr/dsmrreader/provisioning/requirements/base.txt --no-cache-dir \
    && python3 -m pip install psycopg2 --no-cache-dir \
    && apk --purge del .build-deps \
    && rm -rf /var/cache/apk/* \
    && rm -rf /tmp/*

RUN mkdir -p /run/nginx/ \
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log \
    && rm -f /etc/nginx/conf.d/default.conf \
    && mkdir -p /var/www/dsmrreader/static \
    && cp -f /dsmr/dsmrreader/provisioning/nginx/dsmr-webinterface /etc/nginx/conf.d/dsmr-webinterface.conf

COPY ./app-binaries /app-binaries
RUN chmod u+x /app-binaries/*.sh

COPY ./app-config/supervisord.ini /etc/supervisor.d/supervisord.ini

EXPOSE 80 443

WORKDIR /dsmr

CMD ["/bin/bash", "-c", "/app-binaries/run.sh"]
