#!/bin/bash

set -eo pipefail
COMMAND="$@"

# Copy configuration
su dsmr -c "cp /home/dsmr/app/dsmrreader/provisioning/django/postgresql.py /home/dsmr/app/dsmrreader/settings.py"
su dsmr -c "sed -i 's/localhost/dsmrdb/g' /home/dsmr/app/dsmrreader/settings.py"

# Run migrations
su dsmr -c "python3 manage.py migrate --noinput"
su dsmr -c "python3 manage.py collectstatic --noinput"

# Override command if needed - this allows you to run
# python3 manage.py for example. Keep in mind that the
# WORKDIR is set to /home/dsmr/app.
if [ -n "$COMMAND" ]; then
	echo "ENTRYPOINT: Executing override command"
	exec $COMMAND
fi

if [ -z "${DSMR_USER}" ] || [ -z "$DSMR_EMAIL" ] || [ -z "${DSMR_PASSWORD}" ]; then
	echo "DSMR web credentials not set. Exiting."
	exit 1
fi

# Create an admin user
su dsmr -c "python3 manage.py shell --plain << PYTHON
from django.contrib.auth.models import User
if not User.objects.filter(username='${DSMR_USER}'):
	User.objects.create_superuser('${DSMR_USER}', '${DSMR_EMAIL}', '${DSMR_PASSWORD}')
	print('${DSMR_USER} created')
else:
	print('${DSMR_USER} already exists')
PYTHON"

# Run supervisor
/usr/bin/supervisord -n
