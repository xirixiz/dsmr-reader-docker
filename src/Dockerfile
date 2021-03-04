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
    ca-certificates \
    gnupg \
    nginx \
    openssl \
    netcat \
    mariadb-client \
    jq \
    vim \
    locales \
    supervisor

RUN dpkg-reconfigure locales \
    && locale-gen C.UTF-8 \
    && /usr/sbin/update-locale LANG=C.UTF-8

RUN echo "deb http://archive.ubuntu.com/ubuntu/ focal main restricted universe multiverse" > /etc/apt/sources.list.d/ubuntu-main.list \
    && apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 3B4FE6ACC0B21F32 40976EAF437D05B5 \
    && echo "deb http://apt.postgresql.org/pub/repos/apt buster-pgdg main" > /etc/apt/sources.list.d/pgdg.list \
    && curl -Ssl https://www.postgresql.org/media/keys/ACCC4CF8.asc | APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1 apt-key add - \
    && apt-get update \
    && apt-get -y install postgresql-client-12

RUN apt-get update \
    && apt-get install -y \
    build-essential \
    make \
    gcc \
    libpq-dev \
    python3-dev \
    default-libmysqlclient-dev \
    && python -m pip install -r /dsmr/dsmrreader/provisioning/requirements/base.txt --no-cache-dir \
    && python -m pip install psycopg2 --no-cache-dir \
    && python -m pip install mysqlclient --no-cache-dir \
    && apt-get remove -y --purge \
    build-essential \
    make \
    gcc \
    libpq-dev \
    python3-dev \
    default-libmysqlclient-dev \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*

RUN cp -f /dsmr/dsmrreader/provisioning/django/settings.py.template /dsmr/dsmrreader/settings.py

RUN mkdir -p /run/nginx/ \
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log \
    && rm -rf /etc/nginx/sites-enabled/default \
    && mkdir -p /var/www/dsmrreader/static \
    && cp -f /dsmr/dsmrreader/provisioning/nginx/dsmr-webinterface /etc/nginx/sites-available/ \
    && ln -s /etc/nginx/sites-available/dsmr-webinterface /etc/nginx/sites-enabled/

RUN curl -Ssl 'https://api.github.com/repos/dsmrreader/dsmr-reader/releases/latest' | jq -r .tag_name > /dsmr/DSMR_RELEASE

COPY ./app /app
RUN chmod u+x /app/*.sh

COPY ./config/supervisord.conf  /etc/supervisor/conf.d/supervisord.conf
COPY ./config/bashrc /root/.bashrc

EXPOSE 80 443

WORKDIR /dsmr

CMD ["/bin/bash", "-c", "/app/run.sh"]
