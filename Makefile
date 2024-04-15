OUTPUT := output
OUTPUT := $(abspath $(OUTPUT))

build:
	exec docker build --pull --rm --format docker --build-arg DSMR_VERSION="5.11.0" --platform="linux/amd64" --build-arg QEMU_ARCH="x86_64" --build-arg DOCKER_TARGET_RELEASE="2099.09.09" -t dsmr_test_image .

test: build
	exec docker run --rm --name dsmr --network host dsmr_test_image

shell:
	exec docker exec -ti dsmr bash


# docker build --pull --rm --format docker --build-arg DSMR_VERSION="5.11.0" --platform="linux/amd64" --build-arg QEMU_ARCH="x86_64" --build-arg DOCKER_TARGET_RELEASE="2099.09.09" -t dsmr_test_image .; docker save localhost/dsmr_test_image:latest > dsmr_dev; scp -O dsmr_dev xirixiz@nas.skynet:/volume1/onedrive/smarthome
# docker image load < dsmr_dev ; ./docker.sh dsmr_dev; docker logs -f dsmr