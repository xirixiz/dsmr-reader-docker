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
    VACUUM_DB_ON_STARTUP=false

RUN echo 'TERM=xterm-256color' >>  /root/.bashrc \
    && echo 'export PS1="[\u@dsmr] \W # "' >> /root/.bashrc \
    && echo 'alias cp="cp"' >> /root/.bashrc \
    && echo 'alias ll="ls -al"' >> /root/.bashrc

COPY ./s6-overlay/ / \
    ./dsmr/ /dsmr \
    ./root/ /

RUN apk update && \
    apk upgrade --available && \
    apk add --no-cache \
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
    jq

RUN cp -f /dsmr/dsmrreader/provisioning/django/settings.py.template /dsmr/dsmrreader/settings.py

RUN apk add --no-cache --virtual .build-deps gcc python3-dev musl-dev postgresql-dev build-base mariadb-dev libressl-dev libffi-dev cargo rust \
    && python3 -m pip install -r /dsmr/dsmrreader/provisioning/requirements/base.txt --no-cache-dir \
    && python3 -m pip install psycopg2 --no-cache-dir \
    && python3 -m pip install mysqlclient --no-cache-dir

RUN mkdir -p /run/nginx/ \
    && rm -f /etc/nginx/conf.d/default.conf \
    && mkdir -p /var/www/dsmrreader/static \
    && cp -f /dsmr/dsmrreader/provisioning/nginx/dsmr-webinterface /etc/nginx/conf.d/dsmr-webinterface.conf

RUN apk --purge del .build-deps \
    && apk --purge del \
    && rm -rf /var/cache/apk/* \
    && rm -rf /var/tmp/* \
    && rm -rf /usr/src/* \
    rm -rf /tmp/*

RUN chmod 766 /proc/self/fd/1 \
    && chmod 766 /dev/fd/1

RUN curl -Ssl 'https://api.github.com/repos/dsmrreader/dsmr-reader/releases/latest' | jq -r .tag_name > /DSMR_RELEASE

WORKDIR /dsmr

EXPOSE 80/tcp 443/tcp

HEALTHCHECK --interval=5s --timeout=2s --retries=20 CMD /healthcheck.sh || exit 1

ENTRYPOINT ["/init"]
