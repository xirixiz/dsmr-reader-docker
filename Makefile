OUTPUT := output
OUTPUT := $(abspath $(OUTPUT))

IMAGE ?= dsmr_test_image
DSMR_VERSION ?= 6.0rc7
PLATFORM ?= linux/amd64

.PHONY: build test podman-up podman-down shell \
        clean-image clean-stages clean-build-cache clean-volumes clean-dev

build:
	exec podman build --pull --rm --format docker \
		--build-arg DSMR_VERSION="$(DSMR_VERSION)" \
		--platform="$(PLATFORM)" \
		-t "$(IMAGE)" .

test: build
	exec podman run --rm --name dsmr --network host "$(IMAGE)"

podman-up:
	exec podman-compose -f container-compose-development.yaml up

podman-down:
	exec podman-compose -f container-compose-development.yaml down

shell:
	exec podman exec -ti dsmr bash

clean-image:
	@echo "Removing DSMR test image..."
	@podman images -q "$(IMAGE)" | xargs -r podman rmi
	@echo "Done."

clean-stages:
	@echo "Removing dangling podman build stage images..."
	@podman image prune -f
	@echo "Done."

clean-build-cache:
	@echo "Removing unused podman build cache..."
	@podman buildx prune -f
	@echo "Done."

clean-volumes:
	@echo "Removing DSMR podman volumes..."
	@podman volume ls -q | grep '^dsmr' | xargs -r podman volume rm
	@echo "Done."

clean-dev:
	@echo "Cleaning DSMR podman development artifacts..."
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
