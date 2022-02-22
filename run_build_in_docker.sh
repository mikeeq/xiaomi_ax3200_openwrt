#!/usr/bin/env bash

RUN_PATH=$PWD
SCRIPT_PATH=${SCRIPT_PATH:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

echo "===]> Info: RUN_PATH=$RUN_PATH"
echo "===]> Info: SCRIPT_PATH=$SCRIPT_PATH"

DOCKER_IMAGE=debian:buster
RUN_SHELL=${RUN_SHELL:-false}

# mkdir -p ${RPMBUILD_HOST_PATH}

# docker pull ${DOCKER_IMAGE}
if [[ $RUN_SHELL == true ]]; then
  docker run \
    -it \
    --rm \
    -v "$(pwd)":/repo \
    -w /repo \
    ${DOCKER_IMAGE} \
    /bin/bash
else
  docker run \
    -t \
    --rm \
    -v "$(pwd)":/repo \
    -w /repo \
    ${DOCKER_IMAGE} \
    /bin/bash -c './build_in_docker.sh'
fi
