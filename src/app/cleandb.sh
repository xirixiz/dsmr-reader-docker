#!/usr/bin/env bash

if [[ ${DB_ENGINE} == *"postgres"* ]]; then
    if [[ $1 = "-v" ]]; then
        PGPASSWORD=${DB_PASS} /usr/bin/vacuumdb -f -v -h ${DB_HOST} -p ${DB_PORT} -d ${DB_NAME} -U ${DB_USER}
    else
        PGPASSWORD=${DB_PASS} /usr/bin/vacuumdb -f -h ${DB_HOST} -p ${DB_PORT} -d ${DB_NAME} -U ${DB_USER}
    fi
else
    echo "The database engine is set to ${DB_ENGINE}, this script only works with a Postgresql database backend."
    exit
fi