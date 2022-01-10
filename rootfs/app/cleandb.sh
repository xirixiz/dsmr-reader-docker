#!/usr/bin/with-contenv bash

if [[ "${DJANGO_DATABASE_ENGINE}" == *"postgres"* ]]; then
    if [[ $1 = "-v" ]]; then
        PGPASSWORD="${DJANGO_DATABASE_PASSWORD}" /usr/bin/vacuumdb -f -v -h "${DJANGO_DATABASE_HOST}" -p "${DJANGO_DATABASE_PORT}" -d "${DJANGO_DATABASE_NAME}" -U "${DJANGO_DATABASE_USER}"
    else
        PGPASSWORD="${DJANGO_DATABASE_PASSWORD}" /usr/bin/vacuumdb -f -h "${DJANGO_DATABASE_HOST}" -p "${DJANGO_DATABASE_PORT}" -d "${DJANGO_DATABASE_NAME}" -U "${DJANGO_DATABASE_USER}"
    fi
else
    echo "The database engine is set to ${DJANGO_DATABASE_ENGINE}, this script only works with a Postgresql database backend."
    exit
fi