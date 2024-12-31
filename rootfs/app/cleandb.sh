#!/command/with-contenv bash
# shellcheck shell=bash

set -euo pipefail

# Functie voor validatie van verplichte omgevingsvariabelen
validate_env_vars() {
    local vars=("DJANGO_DATABASE_ENGINE" "DJANGO_DATABASE_PASSWORD" "DJANGO_DATABASE_HOST" \
                "DJANGO_DATABASE_PORT" "DJANGO_DATABASE_NAME" "DJANGO_DATABASE_USER")
    for var in "${vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            echo "Error: Environment variable $var is not set."
            exit 1
        fi
    done
}

# Controleer of omgevingsvariabelen correct zijn ingesteld
validate_env_vars

# Controleer of de database engine Postgresql is
if [[ "${DJANGO_DATABASE_ENGINE}" != *"postgres"* ]]; then
    echo "Error: Unsupported database engine '${DJANGO_DATABASE_ENGINE}'. This script only works with a Postgresql database backend."
    exit 1
fi

# Bouw de vacuumdb-opdracht
vacuum_command=(
    PGPASSWORD="${DJANGO_DATABASE_PASSWORD}" 
    /usr/bin/vacuumdb -f 
    -h "${DJANGO_DATABASE_HOST}" 
    -p "${DJANGO_DATABASE_PORT}" 
    -d "${DJANGO_DATABASE_NAME}" 
    -U "${DJANGO_DATABASE_USER}"
)

# Voeg verbose-optie toe als vereist
if [[ "${1:-}" == "-v" ]]; then
    vacuum_command+=("-v")
fi

# Voer de opdracht uit
exec "${vacuum_command[@]}"
