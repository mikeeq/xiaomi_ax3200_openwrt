#!/usr/bin/env bash
set -eu -o pipefail
# set -x

RUN_PATH=$PWD
SCRIPT_PATH=${SCRIPT_PATH:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

cd "$SCRIPT_PATH" || exit
# shellcheck disable=SC1091
source helpers/functions.sh

inf "RUN_PATH=$RUN_PATH"
inf "SCRIPT_PATH=$SCRIPT_PATH"

# DOCKER_IMAGE=debian:buster
DOCKER_IMAGE=openwrt
RUN_SHELL=${RUN_SHELL:-false}
SKIP_PULL=${SKIP_PULL:-true}
BUILD_VERBOSE=${BUILD_VERBOSE:-true}
SKIP_DOWNLOAD=${SKIP_DOWNLOAD:-false}

inf "DOCKER_IMAGE=$DOCKER_IMAGE"
inf "RUN_SHELL=$RUN_SHELL"
inf "SKIP_PULL=$SKIP_PULL"
inf "BUILD_VERBOSE=$BUILD_VERBOSE"
inf "SKIP_DOWNLOAD=$SKIP_DOWNLOAD"

docker build -t openwrt .

# docker pull ${DOCKER_IMAGE}
if [[ $RUN_SHELL == true ]]; then
  DOCKER_ARGS="-i"
  DOCKER_COMMAND="/bin/bash"
else
  DOCKER_ARGS=""
  # shellcheck disable=SC2089
  DOCKER_COMMAND="/bin/bash -c './build_image_in_docker.sh'"
fi

# shellcheck disable=SC2086,SC2090
docker run \
  $DOCKER_ARGS \
  -t \
  --rm \
  -e USER_ID="$(id -u)" \
  -e GROUP_ID="$(id -g)" \
  -e ARTIFACTS_PATH="/repo/artifacts" \
  -e OPENWRT_PATH="/repo/openwrt" \
  -e SKIP_PULL="$SKIP_PULL" \
  -e BUILD_VERBOSE="$BUILD_VERBOSE" \
  -e SKIP_DOWNLOAD="$SKIP_DOWNLOAD" \
  -v "$(pwd)":/repo \
  -w /repo \
  "${DOCKER_IMAGE}" \
  $DOCKER_COMMAND
