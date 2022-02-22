#!/usr/bin/env bash

RUN_PATH=$PWD
SCRIPT_PATH=${SCRIPT_PATH:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

echo "===]> Info: RUN_PATH=$RUN_PATH"
echo "===]> Info: SCRIPT_PATH=$SCRIPT_PATH"

echo "===]> Info: Pull official openwrt repo"

OPENWRT_GIT_URL=https://github.com/openwrt/openwrt.git
OPENWRT_GIT_BRANCH_NAME=master
OPENWRT_GIT_COMMIT_HASH=cbfce9236754700a343632fff8e035acbc1b1384
OPENWRT_GIT_PATH=/tmp/openwrt/upstream

git clone --single-branch --branch ${OPENWRT_GIT_BRANCH_NAME} ${OPENWRT_GIT_URL} ${OPENWRT_GIT_PATH}

cd ${OPENWRT_GIT_PATH}
git checkout ${OPENWRT_GIT_COMMIT_HASH}

echo "===]> Info: Pull namidairo openwrt repo with xiaomi support"

OPENWRT_NAMIDAIRO_GIT_URL=https://github.com/namidairo/openwrt.git
OPENWRT_NAMIDAIRO_GIT_BRANCH_NAME=ax6s
OPENWRT_NAMIDAIRO_GIT_COMMIT_HASH=78a9bee50bc116f443a56d2c094f5c3d3be5c868
OPENWRT_NAMIDAIRO_GIT_PATH=/tmp/openwrt/namidairo

git clone ${OPENWRT_NAMIDAIRO_GIT_URL} ${OPENWRT_NAMIDAIRO_GIT_PATH}

cd ${OPENWRT_NAMIDAIRO_GIT_PATH}
git checkout ${OPENWRT_NAMIDAIRO_GIT_BRANCH_NAME}

git diff master ${OPENWRT_NAMIDAIRO_GIT_BRANCH_NAME} > /tmp/patchfile

cd ${OPENWRT_GIT_PATH}
git apply /tmp/patchfile

echo "===]> Info: Add build scripts"

# https://gitlab.com/db260179/openwrt-base/-/tree/master/docker
# https://gitlab.com/db260179/openwrt-base/-/archive/master/openwrt-base-master.zip?path=docker
# https://gitlab.com/db260179/openwrt-base/-/raw/master/build.sh?inline=false

curl -Ls  https://gitlab.com/db260179/openwrt-base/-/archive/master/openwrt-base-master.zip?path=docker -o docker.zip
unzip docker.zip
mv openwrt-base-master-docker/docker ./
rm -rfv docker.zip openwrt-base-master-docker

# curl -Ls https://gitlab.com/db260179/openwrt-base/-/raw/master/build.sh?inline=false -o build.sh
# chmod +x build.sh

cp -rfv $SCRIPT_PATH/scripts/build.sh ./
cp -rfv $SCRIPT_PATH/scripts/config.buildinfo ./.config

if [[ $IN_DOCKER == true ]]; then
  echo "===]> Info: Build OpenWRT image in Docker"
  ./build.sh build-official
else
  echo "===]> Info: Build Docker image"
  cd docker
  ./run-build.sh build-image

  echo "===]> Info: Build OpenWRT image"
  ./run-build.sh build-official
fi

find bin/.
