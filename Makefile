OUTPUT := output
OUTPUT := $(abspath $(OUTPUT))

build:
	exec docker build --pull --rm --format docker --build-arg DSMR_VERSION=5.11.0 --platform=linux/amd64 --build-arg QEMU_ARCH="x86_64" --build-arg DOCKER_TARGET_RELEASE=2099.09.09 -t dsmr_test_image .

test: build
	exec docker run --rm --network host dsmr_test_image
