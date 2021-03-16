#!/usr/bin/env bash

if [[ ! -d "./dsmr" ]]; then
    export APP_VERSION=$(curl -Ssl 'https://api.github.com/repos/dsmrreader/dsmr-reader/releases/latest' | jq -r .tag_name)
    echo "==> Fetching DSMR version ${APP_VERSION}."
    mkdir -p ./dsmr
    cd dsmr
    wget -N https://github.com/dsmrreader/dsmr-reader/archive/${APP_VERSION}.tar.gz
    wget -N -O dsmr_datalogger_api_client.py https://raw.githubusercontent.com/dsmrreader/dsmr-reader/v4/dsmr_datalogger/scripts/dsmr_datalogger_api_client.py
    tar -zxf ${APP_VERSION}.tar.gz --strip-components=1
    rm -rf ${APP_VERSION}.tar.gz
    echo "==> Fetching DSMR done."
fi

if [[ -d "./dsmr" ]]; then
    echo "==> Building Docker image."
    export BASE_VERSION=python:3-alpine
    docker build --build-arg BASE=${BASE_VERSION} . -t xirixiz/dsmr-reader-docker:local
fi

echo "==> Build succesful, cleanup leftovers?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) rm -rf dsmr; break;;
        No ) exit;;
    esac
done

echo "==> Build succesful, cleanup image?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) docker rmi -f xirixiz/dsmr-reader-docker:local; break;;
        No ) exit;;
    esac
done