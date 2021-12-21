#!/usr/bin/env bash

TARGET=localhost
CURL_OPTS="--connect-timeout 15 --silent --show-error --fail"

curl "${CURL_OPTS}" "http://${TARGET}/about" >/dev/null