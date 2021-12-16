#!/usr/bin/env sh

#---------------------------------------------------------------------------------------------------------------------------
# VARIABLES
#---------------------------------------------------------------------------------------------------------------------------
: "${DEBUG:=false}"
: "${COMMAND:=$@}"
: "${TIMER:=60}"
: "${DSMR_GIT_REPO:=dsmrreader/dsmr-reader}"

#---------------------------------------------------------------------------------------------------------------------------
# MAIN
#---------------------------------------------------------------------------------------------------------------------------

[ "${DEBUG}" = true ] && set -o xtrace

export SD_AUTOSTART_DATALOGGER=true
export SD_AUTORESTART_DATALOGGER=true
export SD_AUTOSTART_REMOTE_DATALOGGER=false
export SD_AUTORESTART_REMOTE_DATALOGGER=false
export SD_AUTOSTART_BACKEND=true
export SD_AUTORESTART_BACKEND=true
export SD_AUTOSTART_WEBINTERFACE=true
export SD_AUTORESTART_WEBINTERFACE=true

cmd=$(command -v python3)
"${cmd}" /dsmr/manage.py migrate --noinput
"${cmd}" /dsmr/manage.py collectstatic --noinput
"${cmd}" /dsmr/manage.py dsmr_superuser

cmd=$(command -v supervisord)
exec "${cmd}" -n -c /etc/supervisor.d/supervisord.ini
