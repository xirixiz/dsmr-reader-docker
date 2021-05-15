#!/usr/bin/env bash
#set -o errexit
#set -o pipefail
#set -o nounset

#---------------------------------------------------------------------------------------------------------------------------
# VARIABLES
#---------------------------------------------------------------------------------------------------------------------------
: "${DEBUG:=false}"
: "${COMMAND:=$@}"
: "${TIMER:=60}"
: "${DSMR_GIT_REPO:=dsmrreader/dsmr-reader}"

#---------------------------------------------------------------------------------------------------------------------------
# FUNCTIONS
#---------------------------------------------------------------------------------------------------------------------------
function _info  () { printf "\\r[ \\033[00;34mINFO\\033[0m ] %s\\n" "$@"; }
function _warn  () { printf "\\r\\033[2K[ \\033[0;33mWARN\\033[0m ] %s\\n" "$@"; }
function _error () { printf "\\r\\033[2K[ \\033[0;31mFAIL\\033[0m ] %s\\n" "$@"; }
function _debug () { printf "\\r[ \\033[00;37mDBUG\\033[0m ] %s\\n" "$@"; }

function _pre_reqs() {
  alias cp="cp"
  alias ll="ls -al"

  _info "DSMR release: $(cat /app/DSMR_RELEASE)"

  _info "Removing existing PID files..."
  rm -f /var/tmp/*.pid

  _info "Creating log directory..."
  mkdir -p /var/log/supervisor/

  _info "Setting architecture requirements..."
  _detect_architecture
}

function _detect_architecture() {
    arch=$(uname -m)
    # _info "uname -m output: ${arch}"
    longbit=$(getconf LONG_BIT)
    if [[ "$arch" == 'x86_64' ]]; then
      if [[ "$longbit" = '32' ]]; then
        arch="i386"
        _info "X32 Architecture"
      else
        arch="amd64"
        _info "X64 Architecture"
      fi
    fi
    if [[ "$arch" == 'x86_32' ]]; then
      arch="i386"
      _info "X32 Architecture"
    fi
    if [[ "$arch" == 'armv7l' ]]; then
      arch="ARM"
      _info "ARM Architecture"
      wget https://ftp.debian.org/debian/pool/main/libs/libseccomp/libseccomp2_2.5.1-1_armhf.deb -P /tmp
      dpkg -i /tmp/libseccomp2_2.5.1-1_armhf.deb
      rm -f /tmp/libseccomp2_2.5.1-1_armhf.deb
    fi
    if [[ "$arch" == 'aarch64' ]]; then
      arch="ARM64"
      _info "ARM Architecture"
    fi
    if [ "$arch" == 'unknown' ]; then
      #Assuming amd64, need to address certain distros uname giving "unknown"
      arch="amd64"
      _info "X64 Architecture"
    fi
}

function _dsmr_datalogger_mode() {
  if [[ "${DATALOGGER_MODE}" = standalone ]]; then
    _info "Configuring DSMR in standlone datalogger mode...."
    export SD_AUTOSTART_DATALOGGER=true
    export SD_AUTORESTART_DATALOGGER=true
    export SD_AUTOSTART_REMOTE_DATALOGGER=false
    export SD_AUTORESTART_REMOTE_DATALOGGER=false
    export SD_AUTOSTART_BACKEND=true
    export SD_AUTORESTART_BACKEND=true
    export SD_AUTOSTART_WEBINTERFACE=true
    export SD_AUTORESTART_WEBINTERFACE=true
  elif [[ "${DATALOGGER_MODE}" = sender ]]; then
    _info "Configuring DSMR in sender datalogger mode...."
    export SD_AUTOSTART_DATALOGGER=false
    export SD_AUTORESTART_DATALOGGER=false
    export SD_AUTOSTART_REMOTE_DATALOGGER=true
    export SD_AUTORESTART_REMOTE_DATALOGGER=true
    export SD_AUTOSTART_BACKEND=false
    export SD_AUTORESTART_BACKEND=false
    export SD_AUTOSTART_WEBINTERFACE=false
    export SD_AUTORESTART_WEBINTERFACE=false
    __dsmr_client_installation
  elif [[ "${DATALOGGER_MODE}" = receiver ]]; then
    _info "Configuring DSMR in receiver datalogger mode...."
    export SD_AUTOSTART_DATALOGGER=false
    export SD_AUTORESTART_DATALOGGER=false
    export SD_AUTOSTART_REMOTE_DATALOGGER=false
    export SD_AUTORESTART_REMOTE_DATALOGGER=false
    export SD_AUTOSTART_BACKEND=true
    export SD_AUTORESTART_BACKEND=true
    export SD_AUTOSTART_WEBINTERFACE=true
    export SD_AUTORESTART_WEBINTERFACE=true
  else
    _error "Invalid value of the DATALOGGER_MODE has been set. Exiting..."
    exit 1
  fi
}

function __dsmr_client_installation() {
  _info "Installing the DSMR remote datalogger client..."
  touch /dsmr/.env
  if [[ -z "${DATALOGGER_API_HOSTS}" || -z "${DATALOGGER_API_KEYS}" || -z "${DATALOGGER_INPUT_METHOD}" ]]; then
      _error "DATALOGGER_API_HOSTS and/or DATALOGGER_API_KEYS and/or DATALOGGER_INPUT_METHOD required values are not set. Exiting..."
      exit 1
  else
    if [[ "${DATALOGGER_INPUT_METHOD}" = ipv4 ]]; then
      _info "Using a network socket for the DSMR remote datalogger..."
      if [[ -z "${DATALOGGER_NETWORK_HOST}" || -z "${DATALOGGER_NETWORK_PORT}" ]]; then
        _error "DATALOGGER_NETWORK_HOST and/or DATALOGGER_NETWORK_PORT required values are not set. Exiting..."
        exit 1
      else
        _info "Adding DATALOGGER_NETWORK_HOST and DATALOGGER_NETWORK_PORT to the DSMR remote datalogger configuration..."
        { echo DATALOGGER_NETWORK_HOST="${DATALOGGER_NETWORK_HOST}"; echo DATALOGGER_NETWORK_PORT="${DATALOGGER_NETWORK_PORT}"; } >> /dsmr/.env
      fi
    elif [[ "${DATALOGGER_INPUT_METHOD}" = serial ]]; then
      _info "Using a serial connection for the DSMR remote datalogger..."
      if [[ -z "${DATALOGGER_SERIAL_PORT}" || -z "${DATALOGGER_SERIAL_BAUDRATE}" ]]; then
        _error "DATALOGGER_SERIAL_PORT and/or DATALOGGER_SERIAL_BAUDRATE required values are not set. Exiting..."
        exit 1
      else
        _info "Adding DATALOGGER_SERIAL_PORT and DATALOGGER_SERIAL_PORT to the DSMR remote datalogger configuration..."
        { echo DATALOGGER_SERIAL_PORT="${DATALOGGER_SERIAL_PORT}"; echo DATALOGGER_SERIAL_PORT="${DATALOGGER_SERIAL_PORT}"; } >> /dsmr/.env
      fi
    else
      _error "Incorrect configuration of the DATALOGGER_INPUT_METHOD value. Exiting..."
      exit 1
    fi
    _info "Adding DATALOGGER_API_HOSTS, DATALOGGER_API_KEYS and DATALOGGER_INPUT_METHOD to the DSMR remote datalogger configuration..."
    { echo DATALOGGER_API_HOSTS="${DATALOGGER_API_HOSTS}"; echo DATALOGGER_API_KEYS="${DATALOGGER_API_KEYS}"; echo DATALOGGER_INPUT_METHOD="${DATALOGGER_INPUT_METHOD}"; } >> /dsmr/.env
  fi

  if [[ -n "${DATALOGGER_TIMEOUT}" ]]; then
    _info "Adding DATALOGGER_TIMEOUT to the DSMR remote datalogger configuration..."
    echo DATALOGGER_TIMEOUT="${DATALOGGER_TIMEOUT}" >> /dsmr/.env
  fi

  if [[ -n "${DATALOGGER_SLEEP}" ]]; then
    _info "Adding DATALOGGER_SLEEP to the DSMR remote datalogger configuration..."
    echo DATALOGGER_SLEEP="${DATALOGGER_SLEEP}" >> /dsmr/.env
  fi

  if [[ -n "${DATALOGGER_DEBUG_LOGGING}" ]]; then
    _info "Adding DATALOGGER_DEBUG_LOGGING to the DSMR remote datalogger configuration..."
    echo DATALOGGER_DEBUG_LOGGING="${DATALOGGER_DEBUG_LOGGING}" >> /dsmr/.env
  fi
}

function _override_entrypoint() {
  if [[ -n "${COMMAND}" ]]; then
    _info "ENTRYPOINT: Executing override command..."
    exec "${COMMAND}"
  fi
}

function _check_device() {
  _info "Fixing /dev/ttyUSB* security..."
  [[ -e '/dev/ttyUSB0' ]] && chmod 666 /dev/ttyUSB*
}

function _check_db_availability() {
  _info "Verifying if the DSMR web credential variables have been set..."
  if [[ -z "${DSMRREADER_ADMIN_USER}" ]] || [[ -z "${DSMRREADER_ADMIN_PASSWORD}" ]]; then
    _error "DSMR web credentials not set. Exiting..."
    exit 1
  fi
  if [[ ! -z "${DJANGO_DATABASE_ENGINE}" ]]; then
    _info "Verifying database connectivity to host: ${DJANGO_DATABASE_HOST} with port: ${DJANGO_DATABASE_PORT}..."
    for i in {1..30}; do
      if ! nc -z "${DJANGO_DATABASE_HOST}" "${DJANGO_DATABASE_PORT}"; then
        sleep 1
        printf "\\rTesting database connectivity: %s second(s) of 30 seconds..." "$i"
        if [[ $i == 30 ]]; then
          _error "Database connectivity couldn't be verified! Please verify your settings. Exiting..."
          exit 1
        fi
      else
        _info "Database connectivity successfully verified!"
        if [[ "${VACUUM_DB_ON_STARTUP}" = true ]] ; then
          _cleandb
        fi
        break
      fi
    done
  fi
}

function _run_post_config() {
  _info "Running post configuration..."
  cmd=$(command -v python3)
  "${cmd}" /dsmr/manage.py migrate --noinput
  "${cmd}" /dsmr/manage.py collectstatic --noinput
  "${cmd}" /dsmr/manage.py dsmr_superuser
}

function _nginx_ssl_configuration() {
  _info "Checking for NGINX SSL configuration..."
  if [[ -n "${ENABLE_NGINX_SSL}" ]]; then
    if [[ "${ENABLE_NGINX_SSL}" = true ]] ; then
      if [[ ! -f "/etc/ssl/private/fullchain.pem" ]] && [[ ! -f "/etc/ssl/private/fullchain.pem" ]] ; then
        _error "Make sure /etc/ssl/private/fullchain.pem and /etc/ssl/private/privkey.pem are mounted in the Docker container and exist!"
        exit 1
      else
        _info "Required files /etc/ssl/private/fullchain.pem and /etc/ssl/private/privkey.pem exists."
      fi
      if grep -q "443" /etc/nginx/http.d/dsmr-webinterface.conf; then
        _info "SSL has already been enabled..."
      else
        sed -i '/listen\s*80/r '<(cat <<- END_HEREDOC
        listen 443 ssl;
        ssl_certificate /etc/ssl/private/fullchain.pem;
        ssl_certificate_key /etc/ssl/private/privkey.pem;
END_HEREDOC
        ) /etc/nginx/http.d/dsmr-webinterface.conf
      fi
      if nginx -c /etc/nginx/nginx.conf -t 2>/dev/null; then
        _info "NGINX SSL configured and enabled"
        return
      else
        _error "NGINX configuration error"
        exit 1
      fi
    fi
  fi
  _info "ENABLE_NGINX_SSL is disabled, nothing to see here. Continuing..."
}

function _generate_auth_configuration() {
  _info "Checking for HTTP AUTHENTICATION configuration..."
  if [[ -n "${ENABLE_HTTP_AUTH}" ]]; then
    if [[ "${ENABLE_HTTP_AUTH}" = true ]] ; then
      _info "ENABLE_HTTP_AUTH is enabled, let's secure this!"
      canWeContinue=true
      if [[ -z "${HTTP_AUTH_USERNAME}" ]]; then
        _warn "Please provide a HTTP_AUTH_USERNAME"
        canWeContinue=false
      fi
      if [[ -z "${HTTP_AUTH_PASSWORD}" ]]; then
        _warn "Please provide a HTTP_AUTH_PASSWORD"
        canWeContinue=false
      fi
      if [[ "${canWeContinue}" = false ]] ; then
        _error "Cannot generate a valid .htpasswd file, please check above warnings."
        exit 1
      fi
      _info "Generating htpasswd..."
	    HTTP_AUTH_CRYPT_PASSWORD=$(openssl passwd -apr1 "${HTTP_AUTH_PASSWORD}")
    	printf "%s:%s\n" "${HTTP_AUTH_USERNAME}" "${HTTP_AUTH_CRYPT_PASSWORD}" > /etc/nginx/htpasswd
      _info "Done! Enabling the configuration in NGINX..."
      sed -i "s/##    auth_basic/    auth_basic/" /etc/nginx/http.d/dsmr-webinterface.conf
      if nginx -c /etc/nginx/nginx.conf -t 2>/dev/null; then
        _info "HTTP AUTHENTICATION configured and enabled"
        return
      else
        _error "NGINX configuration error"
        exit 1
      fi
    fi
  fi
  _info "ENABLE_HTTP_AUTH is disabled, nothing to see here. Continuing..."
}

function _cleandb {
  _info "Vacuum cleaning enabled. Vacuming database..."
  bash /app/cleandb.sh
}

function _start_supervisord() {
  _info "Starting supervisord..."
  _info "Logfiles can be found at: /var/log/supervisor/*.log and /tmp/supervisord.log"
  cmd=$(command -v supervisord)
  "${cmd}" -n -c /etc/supervisor.d/supervisord.ini
}

#---------------------------------------------------------------------------------------------------------------------------
# MAIN
#---------------------------------------------------------------------------------------------------------------------------
[[ "${DEBUG}" = true ]] && set -o xtrace

_pre_reqs
_override_entrypoint

if [[ "${DATALOGGER_MODE}" = standalone || "${DATALOGGER_MODE}" = sender ]]; then
  _check_device
fi

if [[ "${DATALOGGER_MODE}" = standalone || "${DATALOGGER_MODE}" = receiver ]]; then
  _check_db_availability
  _run_post_config
  _nginx_ssl_configuration
  _generate_auth_configuration
fi

_dsmr_datalogger_mode
_start_supervisord
