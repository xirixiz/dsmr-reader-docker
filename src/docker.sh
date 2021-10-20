#!/bin/bash
DOCKER_NETWORK_BRIDGE=proxy

function docker_network() {
    if ! docker network ls | grep -w "${DOCKER_NETWORK_BRIDGE}"; then
        echo "* Creating docker network: ${DOCKER_NETWORK_BRIDGE}"
        # https://docs.docker.com/engine/reference/commandline/network_create/#bridge-driver-options
        docker network create \
            -o "com.docker.network.bridge.enable_icc"="true" \
            -o "com.docker.network.bridge.enable_ip_masquerade"="true" \
            -o "com.docker.network.bridge.host_binding_ipv4"="0.0.0.0" \
            -o "com.docker.network.driver.mtu"="1500" \
            ${DOCKER_NETWORK_BRIDGE}
    else
        echo "* Docker network already exists: ${DOCKER_NETWORK_BRIDGE}"
    fi
}

function docker_rm_all() {
    echo "* Stopping all containers..."
    docker rm -f $(docker ps -aq)
}

function docker_rm() {
    if docker ps -a | grep -w "${NAME}"; then
        echo "* Stopping docker container: ${NAME}"
        docker rm -f "${NAME}"
        sleep 1
        docker pull "${IMAGE}"
    else
        echo "* Docker container not running: ${NAME}"
    fi
}

function docker_container_count() {
    echo "* Docker containers running: $(docker ps -aq | wc -l)"
}

function dsmrdb() {
    NAME=dsmrdb
    IMAGE=postgres:13-alpine
    docker_rm
    docker pull "${IMAGE}"
    docker run --detach \
        --name ${NAME} \
        --restart always \
        --volume /etc/localtime:/etc/localtime:ro \
        --volume ${PWD}/dsmr_data/db:/var/lib/postgresql/data:rw \
        --env "POSTGRES_USER=dsmrreader" \
        --env "POSTGRES_PASSWORD=dsmrreader" \
        --env "POSTGRES_DB=dsmrreader" \
        --env-file .env \
        --network ${DOCKER_NETWORK_BRIDGE} \
        --restart unless-stopped \
        ${IMAGE}
    # echo "* Sleeping for 5 seconds before starting DSMR..."
    # sleep 5s
}

function dsmr() {
    NAME=dsmr
    IMAGE=xirixiz/dsmr-reader-docker:local
    docker_rm
    docker pull "${IMAGE}"
    docker run --detach \
        --publish 7777:80 \
        --publish 7778:443 \
        --name ${NAME} \
        --restart always \
        --tty \
        --volume /etc/localtime:/etc/localtime:ro \
        --cap-add NET_ADMIN \
        --env "VACUUM_DB_ON_STARTUP=true" \
        --env "SD_LOGLEVEL=info" \
        --env "DJANGO_DATABASE_HOST=dsmrdb" \
        --env "DJANGO_DATABASE_USER=dsmrreader" \
        --env "DJANGO_DATABASE_PASSWORD=dsmrreader" \
        --env "DJANGO_DATABASE_PORT=5432" \
        --env "DSMRREADER_LOGLEVEL=WARNING" \
        --env "DSMRREADER_ADMIN_USER=admin" \
        --env "DSMRREADER_ADMIN_PASSWORD=admin" \
        --env-file .env \
        --network ${DOCKER_NETWORK_BRIDGE} \
        --restart unless-stopped \
        ${IMAGE}
}

docker_network
# dsmrdb
dsmr

# healthcheck:
#   test: ["CMD", "curl", "-f", "http://localhost:7990"]
#   interval: 10s
#   timeout: 5s
#   retries: 5
# restart: unless-stopped

# services:
#   kong-database:
#     image: postgres:9.5
#     container_name: kong-postgres
#     environment:
#       - POSTGRES_USER=kong
#       - POSTGRES_DB=kong
#       - POSTGRES_HOST_AUTH_METHOD=trust
#     healthcheck:
#       test: ["CMD-SHELL", "pg_isready"]
#       interval: 10s
#       timeout: 5s
#       retries: 5

#   kong-migration:
#     image: kong
#     container_name: kong-migration
#     depends_on:
#       kong-database:
#         condition: service_healthy
#     environment:
#       - KONG_DATABASE=postgres
#       - KONG_PG_HOST=kong-database
#     command: kong migrations bootstrap

#   kong:
#     image: kong
#     container_name: kong
#     restart: always
#     depends_on:
#       kong-database:
#         condition: service_healthy
#       kong-migration:
#         condition: service_started
#     links:
#       - kong-database:kong-database
#     ports:
#       - 8000:8000
#       - 8443:8443
#       - 8001:8001
#       - 8444:8444
#     environment:
#       - KONG_DATABASE=postgres
#       - KONG_PG_HOST=kong-database
#       - KONG_PG_DATABASE=kong
#       - KONG_ADMIN_LISTEN=0.0.0.0:8001
