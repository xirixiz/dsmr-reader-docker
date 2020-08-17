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
: "${DSMR_GIT_REPO:=dennissiemensma/dsmr-reader}"


# DEVELOPMENT
: "${DSMR_UPDATE_ON_STARTUP:=true}"
: "${DSMR_TAG_RELEASE:=true}"


#---------------------------------------------------------------------------------------------------------------------------
# FUNCTIONS
#---------------------------------------------------------------------------------------------------------------------------
function _info  () { printf "\\r[ \\033[00;34mINFO\\033[0m ] %s\\n" "$@"; }
function _warn  () { printf "\\r\\033[2K[ \\033[0;33mWARN\\033[0m ] %s\\n" "$@"; }
function _error () { printf "\\r\\033[2K[ \\033[0;31mFAIL\\033[0m ] %s\\n" "$@"; }
function _debug () { printf "\\r[ \\033[00;37mDBUG\\033[0m ] %s\\n" "$@"; }

function _pre_reqs() {
  _info "Checking if the DSMR web credential variables have been set..."
  if [[ -z "${DSMR_USER}" ]] || [[ -z "${DSMR_PASSWORD}" ]]; then
    _error "DSMR web credentials not set. Exiting..."
    exit 1
  fi

  _info "Checking if the DSMR web credential variables have been set..."
  if [[ -z "${DSMR_UPDATE_ON_STARTUP}" ]] || [[ ! -z "${DSMR_TAG_RELEASE}" ]]; then
    _error "Cannot use a TAG release without DSMR_UPDATE_ON_STARTUP being set. Exiting..."
    exit 1
  fi

  _info "Fixing /dev/ttyUSB* security..."
  [[ -e '/dev/ttyUSB0' ]] && chmod 666 /dev/ttyUSB*

  _info "Removing existing PID files..."
  rm -f /var/tmp/*.pid

  _info "Creating log directory..."
  mkdir -p /var/log/supervisor/
}

function _update_on_startup() {
  if [[ "${DSMR_TAG_RELEASE}" == true ]] ; then
    _info "Using the latest TAG release."
    dsmr_release=$(curl -Ssl "https://api.github.com/repos/${DSMR_GIT_REPO}/tags" | jq -r .[0].name)
  else
    _info "Using the latest release."
    dsmr_release=$(curl -Ssl "https://api.github.com/repos/${DSMR_GIT_REPO}/releases/latest" | jq -r .tag_name)
  fi
  _info "Update on startup enabled! Using latest DSMR release: ${dsmr_release}."
  mkdir -p /dsmr
  rm -rf /dsmr/*
  pushd /dsmr
  wget -N https://github.com/"${DSMR_GIT_REPO}"/archive/"${dsmr_release}".tar.gz
  tar -xf "${dsmr_release}".tar.gz --strip-components=1 --overwrite
  rm -rf "${dsmr_release}".tar.gz
  popd
  yes | cp /dsmr/dsmrreader/provisioning/django/settings.py.template /dsmr/dsmrreader/settings.py
  pip3 install -r /dsmr/dsmrreader/provisioning/requirements/base.txt --no-cache-dir
  yes | cp /dsmr/dsmrreader/provisioning/nginx/dsmr-webinterface /etc/nginx/conf.d/dsmr-webinterface.conf
  rm -rf /tmp/*
}

function _override_entrypoint() {
  if [[ -n "${COMMAND}" ]]; then
    _info "ENTRYPOINT: Executing override command..."
    exec "${COMMAND}"
  fi
}

function _check_db_availability() {
  _info "Verifying if Postgres in running..."
  cmd=$(command -v pg_isready)
  cmd="${cmd} -h ${DB_HOST} -p ${DB_PORT} -U ${DB_USER} -d ${DB_NAME} -t 1"
  while ! ${cmd} >/dev/null 2>&1; do
    TIMER=$((TIMER-1))
    sleep 1
    if [[ "${TIMER}" -eq 0 ]]; then
      _error "Could not connect to database server. Aborting..."
      exit 1
    fi
    echo -n "."
  done
}

function _run_post_config() {
  _info "Running post configuration..."
  cmd=$(command -v python3)
  "${cmd}" manage.py migrate --noinput
  "${cmd}" manage.py collectstatic --noinput
  "${cmd}" manage.py dsmr_superuser
}

function _generate_auth_configuration() {
  _info "Checking for HTTP AUTHENTICATION configuration..."
  if [[ ! -z "${ENABLE_HTTP_AUTH}" ]]; then
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
      printf ${HTTP_AUTH_USERNAME}":$(openssl passwd -apr1 "${HTTP_AUTH_PASSWORD}")\n" > /etc/nginx/htpasswd
      _info "Done! Enabling the configuration in NGINX..."
      sed -i "s/##    auth_basic/    auth_basic/" /etc/nginx/conf.d/dsmr-webinterface.conf
      if [[ $($(nginx -c /etc/nginx/nginx.conf -t 2>/dev/null); echo $?) > 0 ]]; then
        _error "NGINX configuration error"
        exit 1
      fi
      _info "HTTP AUTHENTICATION configured and enabled"
      return
    fi
  fi
  _info "ENABLE_HTTP_AUTH is disabled, nothing to see here."
}

function _start_supervisord() {
  _info "Starting supervisord..."
  _info "Logfiles can be found at: /var/log/supervisor/*.log and /tmp/supervisord.log"
  cmd=$(command -v supervisord)
  "${cmd}" -n
}

#---------------------------------------------------------------------------------------------------------------------------
# MAIN
#---------------------------------------------------------------------------------------------------------------------------
[[ "${DEBUG}" = true ]] && set -o xtrace

_pre_reqs
if [[ "${DSMR_UPDATE_ON_STARTUP}" = true ]] ; then
  _update_on_startup
fi
_override_entrypoint
_check_db_availability
_run_post_config
_generate_auth_configuration
_start_supervisord
