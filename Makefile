OUTPUT := output
OUTPUT := $(abspath $(OUTPUT))

IMAGE ?= dsmr_test_image
DSMR_VERSION ?= 6.0rc8
PLATFORM ?= linux/amd64

COMPOSE ?= podman compose
COMPOSE_FILE ?= container-compose-development.yaml

.PHONY: build test podman-up podman-down shell \
        clean-image clean-stages clean-build-cache clean-volumes clean

build: clean-containers
	exec podman build --pull --rm --format docker \
		--build-arg DSMR_VERSION="$(DSMR_VERSION)" \
		--platform="$(PLATFORM)" \
		-t "$(IMAGE)" .

test: clean-containers build container-up

container-run: clean-containers
	exec podman run --rm --name dsmr --env DSMRREADER_ADMIN_PASSWORD="admin" --network host "$(IMAGE)"

container-up: clean-containers
	exec $(COMPOSE) -f "$(COMPOSE_FILE)" up -d
	exec podman logs -f dsmr

container-down: clean-containers

shell:
	exec podman exec -ti dsmr bash

clean-containers:
	@echo "Stopping DSMR containers..."
	@podman stop dsmr 2>/dev/null || true
	@podman stop dsmrdb 2>/dev/null || true
	@echo "Removing DSMR containers..."
	@podman rm -f dsmr 2>/dev/null || true
	@podman rm -f dsmrdb 2>/dev/null || true
	@echo "Removing DSMR volumes..."
	@podman volume prune -f 2>/dev/null || true
	@echo "Done."

clean-image:
	@echo "Removing DSMR test image..."
	@podman images -q "$(IMAGE)" | xargs -r podman rmi
	@echo "Done."

clean-stages:
	@echo "Removing dangling Podman images..."
	@podman image prune -f
	@echo "Done."

clean-build-cache:
	@echo "Removing unused Podman build cache..."
	@podman builder prune -f
	@echo "Done."

clean-volumes:
	@echo "Removing DSMR Podman volumes..."
	@podman volume ls -q | grep '^dsmr' | xargs -r podman volume rm
	@echo "Done."

clean:
	@echo "Cleaning DSMR Podman development artifacts..."
	-@$(MAKE) podman-down
	@$(MAKE) clean-containers
	@$(MAKE) clean-image
	@$(MAKE) clean-stages
	@$(MAKE) clean-build-cache
	@$(MAKE) clean-volumes
	@echo "Done."

# make build DSMR_VERSION=6.0rc7
# make build DSMR_VERSION=6.0.0 PLATFORM=linux/arm64
# make clean-dev

# podman build --pull --rm --format docker --build-arg DSMR_VERSION="5.11.0" --platform="linux/amd64" --build-arg QEMU_ARCH="x86_64" --build-arg podman_TARGET_RELEASE="2099.09.09" -t dsmr_test_image .; podman save localhost/dsmr_test_image:latest > dsmr_dev; scp -O dsmr_dev xirixiz@nas.skynet:/volume1/onedrive/smarthome
# podman image load < dsmr_dev ; ./podman.sh dsmr_dev; podman logs -f dsmr
