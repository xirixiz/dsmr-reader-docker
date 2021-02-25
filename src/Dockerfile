ARG BASE
FROM ${BASE}

ENV LC_ALL C.UTF-8

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

ENV SD_LOGLEVEL info
ENV SD_USER root
ENV SD_GROUP root

COPY ./dsmr/ /dsmr

RUN apt-get update \
    && apt-get install -y \
        curl \
        nginx \
        openssl \
        netcat \
        postgresql-client \
        default-libmysqlclient-dev \
        mariadb-client \
        jq \
        locales \
        supervisor

RUN apt-get update \
    && apt-get install -y \
        build-essential \
        make \
        gcc \
        python3-dev \
    && python -m pip install -r /dsmr/dsmrreader/provisioning/requirements/base.txt --no-cache-dir \
    && python -m pip install psycopg2 --no-cache-dir \
    && python -m pip install mysqlclient --no-cache-dir \
    && apt-get remove -y --purge \
        python3-dev \
        gcc \
        make \
        build-essential \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*

RUN dpkg-reconfigure locales \
    && locale-gen C.UTF-8 \
    && /usr/sbin/update-locale LANG=C.UTF-8

RUN cp -f /dsmr/dsmrreader/provisioning/django/settings.py.template /dsmr/dsmrreader/settings.py

RUN mkdir -p /run/nginx/ \
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log \
    && rm -f /etc/nginx/conf.d/default.conf \
    && mkdir -p /var/www/dsmrreader/static \
    && cp -f /dsmr/dsmrreader/provisioning/nginx/dsmr-webinterface /etc/nginx/conf.d/dsmr-webinterface.conf

COPY ./app /app
RUN chmod u+x /app/*.sh

COPY ./config/supervisord.ini /etc/supervisor.d/supervisord.ini

EXPOSE 80 443

WORKDIR /dsmr

CMD ["/bin/bash", "-c", "/app/run.sh"]
