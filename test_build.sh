#!/bin/bash

docker build . --build-arg DSMR_VERSION=5.10.4 --build-arg TARGETARCH="amd64" --build-arg TARGETVARIANT="" --build-arg QEMU_ARCH="x86_64" --build-arg DOCKER_TARGET_RELEASE=2099.09.09 -t dsmr_test_image
