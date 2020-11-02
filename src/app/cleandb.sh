#!/usr/bin/env bash

if [[ $1 = "-v" ]]; then
    PGPASSWORD=${DB_PASS} /usr/bin/vacuumdb -f -v -h ${DB_HOST} -d ${DB_NAME} -U ${DB_USER}
else
    PGPASSWORD=${DB_PASS} /usr/bin/vacuumdb -f -h ${DB_HOST} -d ${DB_NAME} -U ${DB_USER}
fi