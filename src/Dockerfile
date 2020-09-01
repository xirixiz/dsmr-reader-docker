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

ENV SD_LOGLEVEL info
ENV SD_USER root
ENV SD_GROUP root
ENV SD_AUTOSTART_DATALOGGER true
ENV SD_AUTORESTART_DATALOGGER true
ENV SD_AUTOSTART_REMOTE_DATALOGGER false
ENV SD_AUTORESTART_REMOTE_DATALOGGER false
ENV SD_AUTOSTART_BACKEND true
ENV SD_AUTORESTART_BACKEND true
ENV SD_AUTOSTART_WEBINTERFACE true
ENV SD_AUTORESTART_WEBINTERFACE true

RUN apk --update add --no-cache \
      bash \
      curl \
      wget \
      nginx \
      openssl \
      postgresql-client \
      gcc \
      python3-dev \
      musl-dev \
      postgresql-dev \
      tzdata \
      jq \
      supervisor

RUN mkdir -p /run/nginx/ \
      && ln -sf /dev/stdout /var/log/nginx/access.log \
      && ln -sf /dev/stderr /var/log/nginx/error.log \
      && rm -f /etc/nginx/conf.d/default.conf \
      && mkdir -p /var/www/dsmrreader/static

COPY ./app/run.sh /run.sh
RUN chmod u+x /run.sh

COPY ./app/supervisord.ini /etc/supervisor.d/supervisord.ini

EXPOSE 80 443

CMD ["/bin/bash", "-c", "/run.sh"]