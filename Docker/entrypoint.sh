#!/bin/bash

set -eo pipefail
COMMAND="$@"

# 100% permissions fail safe
chown -R dsmr: /home/dsmr /var/www/dsmrreader/

DB_PORT=${DB_PORT:-5432}

cmd=$(find /usr/lib/postgresql/ -name pg_isready)
cmd="$cmd -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -t 1"

timeout=60
while ! $cmd >/dev/null 2>&1; do
    timeout=$(expr $timeout - 1)
    if [[ $timeout -eq 0 ]]; then
        echo
        echo "Could not connect to database server. Aborting..."
        return 1
    fi
    echo -n "."
    sleep 1
done
echo

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
