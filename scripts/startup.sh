#!/bin/bash

# UPDATE PIP
pip3 install --upgrade pip

# ADD ROOT TO DIALOUT GROUP
usermod -a -G dialout root

# GIT CLONE
git clone https://github.com/dennissiemensma/dsmr-reader.git /root/dsmr-reader

# VIRTUALENV
mkdir /root/.virtualenvs
virtualenv /root/.virtualenvs/dsmrreader --no-site-packages --python python3
source /root/.virtualenvs/dsmrreader/bin/activate

# DJANGO REQUIREMENTS
pip3 install -r /root/dsmr-reader/dsmrreader/provisioning/requirements/base.txt
pip3 install psycopg2

# NGINX REQUIREMENTS
mkdir -p /var/www/dsmrreader/static

# RUN django tasks
cp /root/dsmr-reader/dsmrreader/provisioning/django/postgresql.py /root/dsmr-reader/dsmrreader/settings.py
sed -i 's/localhost/dsmrdb/g' /root/dsmr-reader/dsmrreader/settings.py
/root/dsmr-reader/manage.py migrate
/root/dsmr-reader/manage.py collectstatic --noinput

if [[ -z ${DSRM_USER} ]] || [[ -z $DSRM_EMAIL ]] || [[ -z ${DSRM_PASSWORD} ]]; then
  echo "DSRM web credentials not set. Exiting."
  exit 1
else
  if echo "from django.contrib.auth.models import User; User.objects.filter(is_superuser=True).exists()" | /root/dsmr-reader/manage.py shell; then
    echo "DSRM web credentials already set!"
  else  
    echo "Setting DSRM web credentials..."
    echo "from django.contrib.auth.models import User; User.objects.create_superuser('(${DSRM_USERNAME})', '(${DSRM_EMAIL})', '(${DSRM_PASSWORD})')" | /root/dsmr-reader/manage.py shell
  fi
fi

# NGINX Config
cp /root/dsmr-reader/dsmrreader/provisioning/nginx/dsmr-webinterface /etc/nginx/sites-enabled/

# START SERVICES
/usr/sbin/nginx
/usr/bin/supervisord -n
