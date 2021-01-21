ARG BASE
FROM ${BASE}

ENV TERM="xterm" \
    DJANGO_SECRET_KEY="dsmrreader" \
    DJANGO_DATABASE_ENGINE="django.db.backends.postgresql" \
    DSMRREADER_SUPPRESS_STORAGE_SIZE_WARNINGS="True" \
    DJANGO_DATABASE_NAME="dsmrreader" \
    DJANGO_DATABASE_USER="dsmrreader" \
    DJANGO_DATABASE_PASSWORD="dsmrreader" \
    DJANGO_DATABASE_HOST="dsmrdb" \
    DJANGO_DATABASE_PORT="5432" \
    DSMRREADER_ADMIN_USER="admin" \
    DSMRREADER_ADMIN_PASSWORD="admin" \
    DATALOGGER_MODE="standalone"

COPY ./dsmr/ /dsmr
COPY ./s6-overlay /
COPY src/root/ /

RUN \
# Update and get dependencies
    apk --update add --no-cache \
      apk upgrade \
      bash \
      curl \
      nginx \
      openssl \
      postgresql-client \
      mariadb-connector-c-dev \
      mariadb-client \
      tzdata \
      jq \
    && \
    \
# Copy dsmrreader default settings file
    cp -f /dsmr/dsmrreader/provisioning/django/settings.py.template /dsmr/dsmrreader/settings.py && \
    \
# Fetch and install Python requirements
    apk add --no-cache --virtual .build-deps gcc python3-dev musl-dev postgresql-dev build-base mariadb-dev && \
    python3 -m pip install -r /dsmr/dsmrreader/provisioning/requirements/base.txt --no-cache-dir && \
    python3 -m pip install psycopg2 --no-cache-dir && \
    python3 -m pip install mysqlclient --no-cache-dir && \
    \
# Configure Nginx
    mkdir -p /run/nginx/ && \
    ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log && \
    rm -f /etc/nginx/conf.d/default.conf && \
    mkdir -p /var/www/dsmrreader/static && \
    cp -f /dsmr/dsmrreader/provisioning/nginx/dsmr-webinterface /etc/nginx/conf.d/dsmr-webinterface.conf && \
    \
# Cleanup
    apk --purge del .build-deps && \
    apk --purge del && \
    apt-get -y autoremove && \
    rm -rf /var/cache/apk/* && \
    rm -rf /var/tmp/* && \
    rm -rf /usr/src/* && \
    rm -rf /tmp/*

EXPOSE 80/tcp 443/tcp

VOLUME /dsmr/backups

WORKDIR /dsmr

ENTRYPOINT ["/init"]

HEALTHCHECK --interval=5s --timeout=2s --retries=20 CMD /healthcheck.sh || exit 1