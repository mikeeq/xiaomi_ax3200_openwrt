#!/usr/bin/env bash

RUN_PATH=$PWD
SCRIPT_PATH=${SCRIPT_PATH:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

echo "===]> Info: RUN_PATH=$RUN_PATH"
echo "===]> Info: SCRIPT_PATH=$SCRIPT_PATH"

TMP_PATH=$SCRIPT_PATH/xiaomi_openwrt
IMAGE_URL="https://www.dropbox.com/s/cbuwbt0b4zztfp2/AX6S-big.zip"


echo "===]> Info: TMP_PATH=$TMP_PATH"
echo "===]> Info: IMAGE_URL=$IMAGE_URL"

mkdir -p $TMP_PATH

echo "===]> Info: Downloading images..."
curl -Ls $IMAGE_URL -o $TMP_PATH/images.zip

cd $TMP_PATH

unzip images.zip
sha256sum ./* > ./sha256
