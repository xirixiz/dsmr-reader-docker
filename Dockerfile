FROM debian:jessie
LABEL maintainer="Bram van Dartel <root@rootrulez.com>"

ARG TAG="v1.23.0"
ENV DEBIAN_FRONTEND="noninteractive"

RUN echo "force-unsafe-io" > /etc/dpkg/dpkg.cfg.d/02apt-speedup \
    && echo "Acquire::http {No-Cache=True;};" > /etc/apt/apt.conf.d/no-cache \
    && apt-get -q update && apt-get -qy dist-upgrade \
    && apt-get install -qy \
        python3 python3-dev python3-pip python3-virtualenv \
        postgresql-client libpq-dev virtualenvwrapper supervisor \
        cu git jq curl sudo wget nginx \
    && pip3 install --upgrade pip \
    && apt-get -y autoremove \
    && apt-get -y clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/*

COPY app/* /
RUN useradd -ms /bin/bash dsmr \
    && mkdir -p /home/dsmr /var/www/dsmrreader/static \
    && usermod -a -G dialout root \
    && usermod -a -G dialout dsmr \
    && git clone https://github.com/dennissiemensma/dsmr-reader.git \
       /home/dsmr/app/ \
    && (cd /home/dsmr/app/ && git checkout -q "$TAG") \
    && pip3 install six \
    && pip3 install -r \
       /home/dsmr/app/dsmrreader/provisioning/requirements/base.txt \
    && pip3 install -r \
       /home/dsmr/app/dsmrreader/provisioning/requirements/postgresql.txt \
    && chmod +x /run.sh \
    && chown dsmr: -R /home/dsmr /var/www/dsmrreader/static \
    && mv /supervisord.conf /etc/supervisor/conf.d/supervisord.conf \
    && mv /home/dsmr/app/dsmrreader/provisioning/django/postgresql.py \
       /home/dsmr/app/dsmrreader/settings.py

# Add Nginx in its own layer
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log \
    && rm /etc/nginx/sites-enabled/default \
    && mv /home/dsmr/app/dsmrreader/provisioning/nginx/dsmr-webinterface \
       /etc/nginx/sites-enabled/

EXPOSE 80 443
WORKDIR /home/dsmr/app/
ENTRYPOINT ["/run.sh"]
