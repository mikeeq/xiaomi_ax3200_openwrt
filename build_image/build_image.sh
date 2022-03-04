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

OPENWRT_PATH=${OPENWRT_PATH:-/tmp/openwrt}

OPENWRT_GIT_URL=https://github.com/openwrt/openwrt.git
OPENWRT_GIT_BRANCH_NAME=master
OPENWRT_GIT_COMMIT_HASH=247eaa44161b0a07e2dd40ffaa181d47ca10a96b
OPENWRT_GIT_PATH=${OPENWRT_PATH}/upstream

# OPENWRT_NAMIDAIRO_GIT_URL=https://github.com/namidairo/openwrt.git
# OPENWRT_NAMIDAIRO_GIT_BRANCH_NAME=ax6s
# # OPENWRT_NAMIDAIRO_GIT_COMMIT_HASH=78a9bee50bc116f443a56d2c094f5c3d3be5c868
# OPENWRT_NAMIDAIRO_GIT_PATH=${OPENWRT_PATH}/namidairo

if [[ ${SKIP_PULL:-false} == false || ! -d ${OPENWRT_GIT_PATH} ]]; then
  inf "Pull official openwrt repo"

  git clone --single-branch --branch ${OPENWRT_GIT_BRANCH_NAME} ${OPENWRT_GIT_URL} "${OPENWRT_GIT_PATH}"

  cd "${OPENWRT_GIT_PATH}"
  git checkout ${OPENWRT_GIT_COMMIT_HASH}

  # inf "Pull namidairo openwrt repo with xiaomi support"

  # git clone ${OPENWRT_NAMIDAIRO_GIT_URL} "${OPENWRT_NAMIDAIRO_GIT_PATH}"

  # cd "${OPENWRT_NAMIDAIRO_GIT_PATH}"
  # git checkout ${OPENWRT_NAMIDAIRO_GIT_BRANCH_NAME}
  # git pull origin master
  # git diff master ${OPENWRT_NAMIDAIRO_GIT_BRANCH_NAME} > "${OPENWRT_PATH}"/patchfile

  inf "Apply namidairo patches to upstream repo"
  cd "${OPENWRT_GIT_PATH}"
  # git apply "${OPENWRT_PATH}"/patchfile
  git apply "${PATCH_PATH}"
fi

inf "Add build scripts"
cd "${OPENWRT_GIT_PATH}"

# curl -Ls https://gitlab.com/db260179/openwrt-base/-/raw/master/build.sh?inline=false -o build.sh
# chmod +x build.sh

cp -rfv "$SCRIPT_PATH"/files/build.sh ./

# set FORCE_UNSAFE_CONFIGURE=1

if [[ $IN_DOCKER == true ]]; then
  inf "Build OpenWRT image in Docker"

  [[ ${SKIP_DOWNLOAD:-false} == true ]] && BUILD_OPTS="nodownload"
  CONFIG_PATH=${SCRIPT_PATH}/files ./build.sh build-official ${BUILD_OPTS:-}
else
  # https://gitlab.com/db260179/openwrt-base/-/tree/master/docker
  # https://gitlab.com/db260179/openwrt-base/-/archive/master/openwrt-base-master.zip?path=docker
  # https://gitlab.com/db260179/openwrt-base/-/raw/master/build.sh?inline=false

  curl -Ls  https://gitlab.com/db260179/openwrt-base/-/archive/master/openwrt-base-master.zip?path=docker -o docker.zip
  unzip docker.zip
  mv openwrt-base-master-docker/docker ./
  rm -rfv docker.zip openwrt-base-master-docker

  inf "Build Docker image"
  cd docker
  ./run-build.sh build-image

  inf "Build OpenWRT image"
  ./run-build.sh build-official
fi
build_exitcode=$?

cd "${OPENWRT_GIT_PATH}"
inf "Listing built images"
ls -ltr bin/targets/mediatek/mt7622/

inf "Listing ax6s images"
find . | grep -i ax6s

exit $build_exitcode
