FROM ubuntu:16.04
MAINTAINER Bram van Dartel <root@rootrulez.com>

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
    apt-get -y autoremove && \
    apt-get -y clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/*

COPY scripts/startup.sh /
RUN chmod 755 /startup.sh

COPY scripts/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

RUN ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log && \
    rm /etc/nginx/sites-enabled/default

EXPOSE 80 443

ENTRYPOINT ["/startup.sh"]
