ARG BASE
FROM ${BASE}

ENV DSMR_USER admin
ENV DSMR_EMAIL root@localhost
ENV DSMR_PASSWORD admin

ENV DB_HOST dsmrdb
ENV DB_PORT 5432
ENV DB_USER dsmrreader
ENV DB_PASS dsmrreader
ENV DB_NAME dsmrreader

ENV SD_LOGLEVEL info
ENV SD_USER root
ENV SD_GROUP root
ENV SD_AUTOSTART_DATALOGGER true
ENV SD_AUTORESTART_DATALOGGER true
ENV SD_AUTOSTART_BACKEND true
ENV SD_AUTORESTART_BACKEND true
ENV SD_AUTOSTART_MQTT true
ENV SD_AUTORESTART_MQTT true

RUN apk --update add --no-cache \
      bash \
      curl \
      wget \
      nginx \
      openssl \
      postgresql-client \
      postgresql-dev \
      tzdata \
      jq \
      supervisor

RUN apk add --virtual .build-deps gcc musl-dev postgresql-dev && \
      apk --purge del .build-deps && \
      rm -rf /tmp/*

RUN mkdir -p /run/nginx/ && \
      ln -sf /dev/stdout /var/log/nginx/access.log && \
      ln -sf /dev/stderr /var/log/nginx/error.log && \
      rm -f /etc/nginx/conf.d/default.conf && \
      mkdir -p /var/www/dsmrreader/static

COPY ./app/run.sh /run.sh
RUN chmod u+x /run.sh

COPY ./app/supervisord.ini /etc/supervisor.d/supervisord.ini

EXPOSE 80 443

CMD ["/run.sh"]
