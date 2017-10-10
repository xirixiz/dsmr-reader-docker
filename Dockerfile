FROM ubuntu:16.04
MAINTAINER Bram van Dartel <root@rootrulez.com>

ENV TAG="v1.9.0"
ENV DEBIAN_FRONTEND="noninteractive"
SHELL ["/bin/bash", "-c"]

RUN echo "force-unsafe-io" > /etc/dpkg/dpkg.cfg.d/02apt-speedup && \
    echo "Acquire::http {No-Cache=True;};" > /etc/apt/apt.conf.d/no-cache && \
    apt-get -q update && \
    apt-get -qy dist-upgrade && \
    apt-get install -qy \
      python3 \
      python3-dev \
      python3-pip \
      python3-virtualenv \
      postgresql-client \
      libpq-dev \
      virtualenvwrapper \
      supervisor \
      cu \
      git \
      jq \
      nginx \
      curl \
      sudo \
      wget \
    && \
    pip3 install --upgrade pip && \
    apt-get -y autoremove && \
    apt-get -y clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/*

COPY scripts/entrypoint.sh /

RUN chmod 755 /entrypoint.sh

RUN usermod -a -G dialout root

COPY scripts/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

RUN git clone https://github.com/dennissiemensma/dsmr-reader.git /root/dsmr-reader \
    && git checkout tags/${TAG}

RUN mkdir /root/.virtualenvs \
    && virtualenv /root/.virtualenvs/dsmrreader --no-site-packages --python python3 \
    && source /root/.virtualenvs/dsmrreader/bin/activate

RUN pip3 install six \
    && pip3 install -r /root/dsmr-reader/dsmrreader/provisioning/requirements/base.txt \
    && pip3 install -r /root/dsmr-reader/dsmrreader/provisioning/requirements/postgresql.txt

RUN mkdir -p /var/www/dsmrreader/static

RUN cp /root/dsmr-reader/dsmrreader/provisioning/django/postgresql.py /root/dsmr-reader/dsmrreader/settings.py \
    && sed -i 's/localhost/dsmrdb/g' /root/dsmr-reader/dsmrreader/settings.py \
    && /root/dsmr-reader/manage.py migrate \
    && /root/dsmr-reader/manage.py collectstatic --noinput

RUN ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log \
    && rm /etc/nginx/sites-enabled/default \
    && cp /root/dsmr-reader/dsmrreader/provisioning/nginx/dsmr-webinterface /etc/nginx/sites-enabled/

EXPOSE 80 443

ENTRYPOINT ["/entrypoint.sh"]
