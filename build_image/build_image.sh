#!/usr/bin/env bash

RUN_PATH=$PWD
SCRIPT_PATH=${SCRIPT_PATH:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

cd $SCRIPT_PATH
source helpers/functions.sh

inf "RUN_PATH=$RUN_PATH"
inf "SCRIPT_PATH=$SCRIPT_PATH"

OPENWRT_PATH=${OPENWRT_PATH:-/tmp/openwrt}

if [[ $SKIP_PULL == true || ! -f /tmp/openwrt/patchfile ]]; then
  inf "Pull official openwrt repo"

  OPENWRT_GIT_URL=https://github.com/openwrt/openwrt.git
  OPENWRT_GIT_BRANCH_NAME=master
  OPENWRT_GIT_COMMIT_HASH=b9251e3b407592f3114e739231088c3d27663c4c
  OPENWRT_GIT_PATH=${OPENWRT_PATH}/upstream

  git clone --single-branch --branch ${OPENWRT_GIT_BRANCH_NAME} ${OPENWRT_GIT_URL} ${OPENWRT_GIT_PATH}

  cd ${OPENWRT_GIT_PATH}
  git checkout ${OPENWRT_GIT_COMMIT_HASH}

  inf "Pull namidairo openwrt repo with xiaomi support"

  OPENWRT_NAMIDAIRO_GIT_URL=https://github.com/namidairo/openwrt.git
  OPENWRT_NAMIDAIRO_GIT_BRANCH_NAME=ax6s
  # OPENWRT_NAMIDAIRO_GIT_COMMIT_HASH=78a9bee50bc116f443a56d2c094f5c3d3be5c868
  OPENWRT_NAMIDAIRO_GIT_PATH=${OPENWRT_PATH}/namidairo

  git clone ${OPENWRT_NAMIDAIRO_GIT_URL} ${OPENWRT_NAMIDAIRO_GIT_PATH}

  cd ${OPENWRT_NAMIDAIRO_GIT_PATH}
  git checkout ${OPENWRT_NAMIDAIRO_GIT_BRANCH_NAME}

  git diff master ${OPENWRT_NAMIDAIRO_GIT_BRANCH_NAME} > ${OPENWRT_PATH}/patchfile

  cd ${OPENWRT_GIT_PATH}
  git apply ${OPENWRT_PATH}/patchfile
fi

inf "Add build scripts"

# curl -Ls https://gitlab.com/db260179/openwrt-base/-/raw/master/build.sh?inline=false -o build.sh
# chmod +x build.sh

cp -rfv $SCRIPT_PATH/files/build.sh ./
cp -rfv $SCRIPT_PATH/files/config.buildinfo ./.config

# set FORCE_UNSAFE_CONFIGURE=1

if [[ $IN_DOCKER == true ]]; then
  inf "Build OpenWRT image in Docker"
  ./build.sh build-official
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

cd ${OPENWRT_GIT_PATH}
# find bin/ | grep -i ".bin"
ls -ltr bin/targets/mediatek/mt7622/ | grep -i -e ".img" -e ".bin"

find . | grep -i ax6s
