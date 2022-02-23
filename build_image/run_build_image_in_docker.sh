#!/usr/bin/env bash

RUN_PATH=$PWD
SCRIPT_PATH=${SCRIPT_PATH:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

cd $SCRIPT_PATH
source helpers/functions.sh

inf "RUN_PATH=$RUN_PATH"
inf "SCRIPT_PATH=$SCRIPT_PATH"

DOCKER_IMAGE=debian:buster
# DOCKER_IMAGE=openwrt
RUN_SHELL=${RUN_SHELL:-false}
SKIP_PULL=${SKIP_PULL:-true}

# mkdir -p ${RPMBUILD_HOST_PATH}

# docker pull ${DOCKER_IMAGE}
if [[ $RUN_SHELL == true ]]; then
  DOCKER_ARGS="-i"
  DOCKER_COMMAND="/bin/bash"
else
  DOCKER_ARGS=""
  DOCKER_COMMAND="/bin/bash -c './build_image_in_docker.sh'"
fi

docker run \
  $DOCKER_ARGS \
  -t \
  --rm \
  -e USER_ID="$(id -u)" \
  -e GROUP_ID="$(id -g)" \
  -e ARTIFACTS_PATH=/repo/artifacts \
  -e SKIP_PULL=$SKIP_PULL \
  -v "$(pwd)":/repo \
  -w /repo \
  ${DOCKER_IMAGE} \
  $DOCKER_COMMAND
