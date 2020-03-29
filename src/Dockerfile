ARG BASE
FROM ${BASE}

ENV DSMR_USER = 'admin'
ENV DSMR_EMAIL = 'root@localhost'
ENV DSMR_PASSWORD = 'admin'

ENV DSMRREADER_NAME = 'dsmrreader'
ENV DSMRREADER_USER = 'dsmrreader'
ENV DSMRREADER_PASSWORD = 'dsmrreader'
ENV DSMRREADER_HOST = 'dsmrdb'
ENV DSMRREADER_PORT = 5432

ENV SD_LOGLEVEL = 'info'
ENV SD_USER = 'root'
ENV SD_GROUP = 'root'
ENV SD_AUTOSTART_DATALOGGER = 'true'
ENV SD_AUTORESTART_DATALOGGER = 'true'
ENV SD_AUTOSTART_BACKEND = 'true'
ENV SD_AUTORESTART_BACKEND = 'true'
ENV SD_AUTOSTART_MQTT = 'true'
ENV SD_AUTORESTART_MQTT = 'true'

COPY ./dsmr/ /dsmr

RUN apk --update add --no-cache \
      bash \
      curl \
      nginx \
      openssl \
      postgresql-client \
      tzdata \
      supervisor

RUN cp /dsmr/dsmrreader/provisioning/django/postgresql.py /dsmr/dsmrreader/settings.py

RUN apk add --virtual .build-deps gcc musl-dev postgresql-dev && \
      pip3 install -r /dsmr/dsmrreader/provisioning/requirements/base.txt --no-cache-dir && \
      pip3 install -r /dsmr/dsmrreader/provisioning/requirements/postgresql.txt --no-cache-dir && \
      apk --purge del .build-deps && \
      rm -rf /tmp/*

RUN mkdir -p /run/nginx/ && \
      ln -sf /dev/stdout /var/log/nginx/access.log && \
      ln -sf /dev/stderr /var/log/nginx/error.log && \
      rm -f /etc/nginx/conf.d/default.conf && \
      mkdir -p /var/www/dsmrreader/static && \
      cp /dsmr/dsmrreader/provisioning/nginx/dsmr-webinterface /etc/nginx/conf.d/dsmr-webinterface.conf

COPY ./app/run.sh /run.sh
RUN chmod u+x /run.sh

COPY ./app/supervisord.ini /etc/supervisor.d/supervisord.ini

EXPOSE 80 443

WORKDIR /dsmr

CMD ["/run.sh"]
