OUTPUT := output
OUTPUT := $(abspath $(OUTPUT))

IMAGE ?= dsmr_test_image
DSMR_VERSION ?= 6.0.1
PLATFORM ?= linux/amd64

COMPOSE ?= docker compose
COMPOSE_FILE ?= container-compose-development.yaml

.PHONY: build test docker-up docker-down shell \
        clean-image clean-stages clean-build-cache clean-volumes clean

build: clean-containers
	exec docker build --pull --rm \
		--build-arg DSMR_VERSION="$(DSMR_VERSION)" \
		--platform="$(PLATFORM)" \
		-t "$(IMAGE)" .

test: clean-containers build container-up

container-run: clean-containers
	exec docker run --rm --name dsmr --env DSMRREADER_ADMIN_USER="admin" --env DSMRREADER_ADMIN_PASSWORD="admin" --network host "$(IMAGE)"

container-up: clean-containers
	exec $(COMPOSE) -f "$(COMPOSE_FILE)" up -d
	exec docker logs -f dsmr

container-down: clean-containers

shell:
	exec docker exec -ti dsmr bash

clean-containers:
	@echo "Stopping DSMR containers..."
	@docker stop dsmr 2>/dev/null || true
	@docker stop dsmrdb 2>/dev/null || true
	@echo "Removing DSMR containers..."
	@docker rm -f dsmr 2>/dev/null || true
	@docker rm -f dsmrdb 2>/dev/null || true
	@echo "Removing DSMR volumes..."
	@docker volume prune -f 2>/dev/null || true
	@echo "Done."

clean-image:
	@echo "Removing DSMR test image..."
	@docker images -q | xargs -r docker rmi
# 	@docker images -q "$(IMAGE)" | xargs -r docker rmi
	@echo "Done."

clean-stages:
	@echo "Removing dangling docker images..."
	@docker image prune -f
	@echo "Done."

clean-build-cache:
	@echo "Removing unused docker build cache..."
	@docker builder prune -f
	@echo "Done."

clean-volumes:
	@echo "Removing DSMR docker volumes..."
	@docker volume ls -q | grep '^dsmr' | xargs -r docker volume rm
	@echo "Done."

clean:
	@echo "Cleaning DSMR docker development artifacts..."
	-@$(MAKE) docker-down
	@$(MAKE) clean-containers
	@$(MAKE) clean-image
	@$(MAKE) clean-stages
	@$(MAKE) clean-build-cache
	@$(MAKE) clean-volumes
	@echo "Done."

# make build DSMR_VERSION=6.0rc7
# make build DSMR_VERSION=6.0.0 PLATFORM=linux/arm64
# make clean-dev

# docker build --pull --rm --format docker --build-arg DSMR_VERSION="5.11.0" --platform="linux/amd64" --build-arg QEMU_ARCH="x86_64" --build-arg docker_TARGET_RELEASE="2099.09.09" -t dsmr_test_image .; docker save localhost/dsmr_test_image:latest > dsmr_dev; scp -O dsmr_dev xirixiz@nas.skynet:/volume1/onedrive/smarthome
# docker image load < dsmr_dev ; ./docker.sh dsmr_dev; docker logs -f dsmr
