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

# Run supervisor
/usr/bin/supervisord -n
