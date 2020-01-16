#!/usr/bin/env bash
set -euo pipefail

echo "##vso[task.setvariable variable=DOCKER_USERNAME;issecret=true]${DOCKER_USERNAME}"
echo "##vso[task.setvariable variable=DOCKER_PASSWORD;issecret=true]${DOCKER_PASSWORD}"
