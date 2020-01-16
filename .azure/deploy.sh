#!/usr/bin/env bash
# set -o errexit
# set -o pipefail
# set -o nounset

#---------------------------------------------------------------------------------------------------------------------------
# VARIABLES
#---------------------------------------------------------------------------------------------------------------------------
: "${DEBUG:=false}"
: "${ARCH_ARR:=amd64 arm32v6 arm64v8}"
: "${DSMR_GIT_REPO:=dennissiemensma/dsmr-reader}"
: "${QEMU_GIT_REPO:=multiarch/qemu-user-static}"
: "${DOCKER_HUB_REPO:=xirixiz/dsmr-reader-docker}"

#---------------------------------------------------------------------------------------------------------------------------
# FUNCTIONS
#---------------------------------------------------------------------------------------------------------------------------
function _info  () { printf "\\r[ \\033[00;34mINFO\\033[0m ] %s\\n" "$@"; }
function _warn  () { printf "\\r\\033[2K[ \\033[0;33mWARN\\033[0m ] %s\\n" "$@"; }
function _error () { printf "\\r\\033[2K[ \\033[0;31mFAIL\\033[0m ] %s\\n" "$@"; }
function _debug () { printf "\\r[ \\033[00;37mDBUG\\033[0m ] %s\\n" "$@"; }

function _preReqs() {
  _info "Creating temporary directory..."
  sudo mkdir -p ./tmp/{dsmr,qemu}


  _info "${DOCKER_FQDN} docker fqdn"
  _info "Logon to the Docker HUB..."
  echo "${DOCKER_PASSWORD}" | docker login -u "${DOCKER_USERNAME}" --password-stdin
}

function _setupDependencies() {
  _info "Setting up dependencies..."
  sudo apt update -y
  sudo apt install realpath python python-pip -y
  sudo apt install --only-upgrade docker-ce -y
  sudo pip install docker-compose || true
  docker info
  docker-compose --version
}

function _updateDockerConfig() {
  _info "Updating docker configuration..."
  echo '{
  "experimental": true,
  "storage-driver": "overlay2",
  "max-concurrent-downloads": 50,
  "max-concurrent-uploads": 50
}' | sudo tee /etc/docker/daemon.json
  sudo service docker restart
}

function _dmsrRelease() {
  dsmr_release=$(curl -Ssl "https://api.github.com/repos/${DSMR_GIT_REPO}/releases/latest" | jq -r .tag_name)
  _info "Using latest DSMR release: ${dsmr_release}."
  pushd ./tmp/dsmr
  if [[ ! -d dsmrreader ]]; then
    sudo wget -N https://github.com/"${DSMR_GIT_REPO}"/archive/"${dsmr_release}".tar.gz
    sudo tar -xf "${dsmr_release}".tar.gz --strip-components=1
    sudo rm -rf "${dsmr_release}".tar.gz
  fi
  popd
}

function _updateQemu() {
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
      sudo wget -N https://github.com/"${QEMU_GIT_REPO}"/releases/download/"${qemu_release}"/x86_64_qemu-"${qemu_arch}"-static.tar.gz
      sudo tar -xf x86_64_qemu-"${qemu_arch}"-static.tar.gz
      sudo rm -rf x86_64_qemu-"${qemu_arch}"-static.tar.gz
    fi
  done
  popd
}

function _generateDockerFiles() {
  _info "Creating Dokcker file for: ${ARCH_ARR}"
  for docker_arch in ${ARCH_ARR}; do
    case ${docker_arch} in
      amd64       ) qemu_arch="x86_64" ;;
      arm32v6     ) qemu_arch="arm" ;;
      arm64v8     ) qemu_arch="aarch64" ;;
      *)
        _error "Unknown target architechture."
        exit 1
    esac
    sudo cp Dockerfile.cross Dockerfile."${docker_arch}"
    sudo sed -i "s|__QEMU_ARCH__|${qemu_arch}|g" Dockerfile."${docker_arch}"
    if [[ ${docker_arch} == "amd64" ]]; then
      sudo sed -i "s|__CROSS_||g" Dockerfile."${docker_arch}"
      sudo sed -i "s|__BASEIMAGE_ARCH__/||g" Dockerfile."${docker_arch}"
    else
      sudo sed -i "s|__BASEIMAGE_ARCH__|${docker_arch}|g" Dockerfile."${docker_arch}"
      sudo sed -i "s|__CROSS_||g" Dockerfile."${docker_arch}"
    fi
  done
}


function _buildDockerFiles() {
  _info "Building Docker images..."
  for docker_arch in ${ARCH_ARR}; do
    _info "Building Docker images for: ${docker_arch}, release ${dsmr_release}."
    docker build -f Dockerfile."${docker_arch}" -t "${DOCKER_HUB_REPO}":"${docker_arch}"-latest .
    docker tag "${DOCKER_HUB_REPO}":"${docker_arch}"-latest "${DOCKER_HUB_REPO}":"${docker_arch}-${dsmr_release}"
    if [[ "${docker_arch}" == "amd64" ]]; then
      docker tag "${DOCKER_HUB_REPO}":"${docker_arch}"-latest "${DOCKER_HUB_REPO}":latest
      docker tag "${DOCKER_HUB_REPO}":"${docker_arch}"-latest "${DOCKER_HUB_REPO}":"${dsmr_release}"
    fi
  done
}

function _pushDockerImages() {
  _info "Pushing Docker images to the Docker HUB..."
  for docker_arch in ${ARCH_ARR}; do
    _info "Pushing Docker images for: ${docker_arch}, release ${dsmr_release}."
    if [[ "${docker_arch}" == "amd64" ]]; then
      sudo docker push "${DOCKER_HUB_REPO}":latest
      sudo docker push "${DOCKER_HUB_REPO}":"${dsmr_release}"
    else
      sudo docker push "${DOCKER_HUB_REPO}":"${docker_arch}"-latest
      sudo docker push "${DOCKER_HUB_REPO}":"${docker_arch}-${dsmr_release}"
    fi
  done
}


#---------------------------------------------------------------------------------------------------------------------------
# MAIN
#---------------------------------------------------------------------------------------------------------------------------
[[ "${DEBUG}" == 'true' ]] && set -o xtrace

_preReqs
_setupDependencies
_updateDockerConfig
_dmsrRelease
_updateQemu
_generateDockerFiles
_buildDockerFiles
_pushDockerImages
