#!/usr/bin/env bash
set -o errexit
set -o pipefail
set -o nounset

#---------------------------------------------------------------------------------------------------------------------------
# VARIABLES
#---------------------------------------------------------------------------------------------------------------------------
: "${DEBUG:=false}"
: "${ARCH_ARR:=amd64 arm32v6 arm64v8}"
: "${DSMR_GIT_REPO:=dennissiemensma/dsmr-reader}"
: "${QEMU_GIT_REPO:=multiarch/qemu-user-static}"
: "${DOCKER_HUB_REPO:=xirixiz/dsmr-reader-docker}"
: "${LOCAL:=}"
: "${HUB:=}"

#---------------------------------------------------------------------------------------------------------------------------
# FUNCTIONS
#---------------------------------------------------------------------------------------------------------------------------
function _info  () { printf "\\r[ \\033[00;34mINFO\\033[0m ] %s\\n" "$@"; }
function _warn  () { printf "\\r\\033[2K[ \\033[0;33mWARN\\033[0m ] %s\\n" "$@"; }
function _error () { printf "\\r\\033[2K[ \\033[0;31mFAIL\\033[0m ] %s\\n" "$@"; }
function _debug () { printf "\\r[ \\033[00;37mDBUG\\033[0m ] %s\\n" "$@"; }

function usage() {
    echo -e "\nusage: $0 [--local --arch <arch> | --hub [--arch <arch>]]"
    echo -e ""
    echo -e "  General parameters:"
    echo -e "    --local          generates a local test image for amd64, arm32v6 or arm64v8."
    echo -e "    --arch           required for local test images, optional for hub images."
    echo -e "    --hub            generates amd64, arm32v6 and arm64v8 Docker images and pushes them to the Docker Hub"
    echo -e "    --debug          debug mode."
    echo -e "    -?               help."
    exit 0
}

function _pre_reqs() {
  _info "Creating temporary directory..."
  mkdir -p ./tmp/{dsmr,qemu}
}

function _dmsr_release() {
  dsmr_release=$(curl -Ssl "https://api.github.com/repos/${DSMR_GIT_REPO}/releases/latest" | jq -r .tag_name)
  _info "Using latest DSMR release: ${dsmr_release}."
  pushd ./tmp/dsmr
  if [[ ! -d dsmrreader ]]; then
    wget -N https://github.com/"${DSMR_GIT_REPO}"/archive/"${dsmr_release}".tar.gz
    tar -xf "${dsmr_release}".tar.gz --strip-components=1
    rm -rf "${dsmr_release}".tar.gz
  fi
  popd
}

function _update_qemu() {
  qemu_release=$(curl -Ssl "https://api.github.com/repos/${QEMU_GIT_REPO}/releases/latest" | jq -r .tag_name)
  _info "Downloading latest Qemu release: ${qemu_release}."
  pushd ./tmp/qemu
  for docker_arch in ${ARCH_ARR}; do
      case ${docker_arch} in
      amd64       ) qemu_arch="x86_64" ;;
      arm32v6     ) qemu_arch="arm" ;;
      arm64v8     ) qemu_arch="aarch64" ;;
      *)
        _error "Unknown target architechture."
        exit 1
    esac
    if [[ ! -f qemu-${qemu_arch}-static ]]; then
      wget -N https://github.com/"${QEMU_GIT_REPO}"/releases/download/"${qemu_release}"/x86_64_qemu-"${qemu_arch}"-static.tar.gz
      tar -xf x86_64_qemu-"${qemu_arch}"-static.tar.gz
      rm -rf x86_64_qemu-"${qemu_arch}"-static.tar.gz
    fi
  done
  popd
}

function _generate_docker_files() {
  echo "$ARCH_ARR"
  for docker_arch in ${ARCH_ARR}; do
    case ${docker_arch} in
      amd64       ) qemu_arch="x86_64" ;;
      arm32v6     ) qemu_arch="arm" ;;
      arm64v8     ) qemu_arch="aarch64" ;;
      *)
        _error "Unknown target architechture."
        exit 1
    esac
    cp Dockerfile.cross Dockerfile."${docker_arch}"
    sed -i '' "s|__QEMU_ARCH__|${qemu_arch}|g" Dockerfile."${docker_arch}"
    if [[ ${docker_arch} == "amd64" ]]; then
      sed -i '' "s/__BASEIMAGE_ARCH__\///g" Dockerfile."${docker_arch}"
    else
      sed -i '' "s|__BASEIMAGE_ARCH__|${docker_arch}|g" Dockerfile."${docker_arch}"
    fi
  done
}

function _build_docker_files() {
  _info "Building Docker images..."
  for docker_arch in ${ARCH_ARR}; do
    _info "Building Docker images for: ${docker_arch}, release ${dsmr_release}."
    docker build -f Dockerfile."${docker_arch}" -t "${DOCKER_HUB_REPO}":"${docker_arch}"-latest .
    docker tag "${DOCKER_HUB_REPO}":"${docker_arch}"-latest "${DOCKER_HUB_REPO}":test-"${docker_arch}"-latest
    docker tag "${DOCKER_HUB_REPO}":"${docker_arch}"-latest "${DOCKER_HUB_REPO}":"${docker_arch}-${dsmr_release}"
    if [[ "${docker_arch}" == "amd64" ]]; then
      docker tag "${DOCKER_HUB_REPO}":"${docker_arch}"-latest "${DOCKER_HUB_REPO}":latest
      docker tag "${DOCKER_HUB_REPO}":"${docker_arch}"-latest "${DOCKER_HUB_REPO}":test-latest
      docker tag "${DOCKER_HUB_REPO}":"${docker_arch}"-latest "${DOCKER_HUB_REPO}":"${dsmr_release}"
    fi
  done
}

function _push_docker_images() {
  _info "Pushing Docker images to the Docker HUB..."
  for docker_arch in ${ARCH_ARR}; do
    _info "Pushing Docker images for: ${docker_arch}, release ${dsmr_release}."
    if [[ "${docker_arch}" == "amd64" ]]; then
      docker push "${DOCKER_HUB_REPO}":latest
      docker push "${DOCKER_HUB_REPO}":"${dsmr_release}"
    else
      docker push "${DOCKER_HUB_REPO}":"${docker_arch}"-latest
      docker push "${DOCKER_HUB_REPO}":"${docker_arch}-${dsmr_release}"
    fi
  done
}

function _push_docker_test_image() {
  _info "Pushing Docker test images to the Docker HUB..."
  for docker_arch in ${ARCH_ARR}; do
    _info "Pushing Docker test images for: ${docker_arch}, release ${dsmr_release}."
    if [[ "${docker_arch}" == "amd64" ]]; then
      docker push "${DOCKER_HUB_REPO}":test-latest
    else
      docker push "${DOCKER_HUB_REPO}":test-"${docker_arch}"-latest
    fi
  done
}


function _cleanup () {
  _info "Cleaning up temporary files..."
  if [[ -d ./tmp ]]; then
    read -p "The ./tmp directory already exists, cleanup?" -n 1 -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      _info "Cleaning up the ./tmp directory!"
      rm -rf ./tmp
    else
      _warn "Skipping cleanup of the ./tmp directory!"
    fi
  fi
  docker images -q | xargs docker rmi -f
  for docker_arch in ${ARCH_ARR}; do
    [[ -f Dockerfile."${docker_arch}" ]] && rm -rf Dockerfile."${docker_arch}"
    continue
  done
}


#---------------------------------------------------------------------------------------------------------------------------
# MAIN
#---------------------------------------------------------------------------------------------------------------------------

[[ $# -eq 0 ]] && usage

while [[ $# -gt 0 ]]; do
    case $1 in
      --local )        LOCAL=local&&ARCH_ARR='';;
      --arch )         shift&&ARCH_ARR=$1;;
      --hub )          HUB=hub;;
      --debug )        DEBUG=true;;
      -? | --help )    usage && exit ;;
      * )              usage && exit 1 ;;
    esac
    shift
done

[[ "${DEBUG}" == 'true' ]] && set -o xtrace

if [[ -n "${LOCAL}" ]]; then
  _info "Generating local Docker image for ${ARCH_ARR}"
  [[ -z "${ARCH_ARR}" ]] && _error "Option --arch not specified!" && exit 1
  _cleanup
  _pre_reqs
  _dmsr_release
  _update_qemu
  _generate_docker_files
  _build_docker_files
  _push_docker_test_image
  _cleanup
fi

if [[ -n "${HUB}" ]]; then
  _info "Generating Docker Hub images for ${ARCH_ARR}"
  _cleanup
  _pre_reqs
  _dmsr_release
  _update_qemu
  _generate_docker_files
  _build_docker_files
  _push_docker_images
  _cleanup
fi
