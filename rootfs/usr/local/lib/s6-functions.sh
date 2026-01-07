#!/command/with-contenv bash
# shellcheck shell=bash

#---------------------------------------------------------------------------------------------------------------------------
# COMMON FUNCTIONS
#---------------------------------------------------------------------------------------------------------------------------
function _log() {
    local level="$1"
    local color="$2"
    shift 2
    printf "\r[ \033[00;%sm%s\033[0m ] %s\n" "${color}" "${level}" "$*" >&2
}

function _info()     { _log "INFO" "34" "$@"; }
function _warn()     { _log "WARN" "33" "$@"; }
function _error()    { _log "FAIL" "31" "$@"; }
function _debug()    { _log "DBUG" "37" "$@"; }
function _success()  { _log "OKAY" "32" "$@"; }
function _progress() { printf "\r[ \033[00;34mINFO\033[0m ] %s" "$@"; }

function _load_s6_vars() {
    if [[ -d /run/s6/container_environment ]]; then
        local file var_name var_value
        while IFS= read -r -d '' file; do
            var_name=$(basename "$file")
            var_value=$(cat "$file")
            export "$var_name=$var_value"
        done < <(find /run/s6/container_environment -type f -print0)
    fi
}

function _normalize_bool_env() {
    local var="$1"
    local val
    val="$(printenv "${var}" 2>/dev/null || echo "false")"

    case "${val,,}" in
        true|1|yes|y|on) export "${var}=true" ;;
        *)               export "${var}=false" ;;
    esac
}

function _normalize_all_enable_vars() {
    local var
    while IFS='=' read -r var _; do
        [[ "${var}" == ENABLE_* ]] || continue
        _normalize_bool_env "${var}"
    done < <(printenv)
}
