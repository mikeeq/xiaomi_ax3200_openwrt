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

[ -x "$(command -v apt-get)" ] || err "Run on Debian!"

pwd
echo "CPU threads: $(nproc --all)"
grep 'model name' /proc/cpuinfo | uniq

inf "Install system dependencies"

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y sudo curl vim gnupg apt-utils

if ! grep -q llvm-toolchain-buster-13 /etc/apt/sources.list; then
  inf "Adding clang-13 apt-get repo"
  echo "
  deb http://apt.llvm.org/buster/ llvm-toolchain-buster main
  deb-src http://apt.llvm.org/buster/ llvm-toolchain-buster main
  # 13
  deb http://apt.llvm.org/buster/ llvm-toolchain-buster-13 main
  deb-src http://apt.llvm.org/buster/ llvm-toolchain-buster-13 main
  # 14
  deb http://apt.llvm.org/buster/ llvm-toolchain-buster-14 main
  deb-src http://apt.llvm.org/buster/ llvm-toolchain-buster-14 main" >> /etc/apt/sources.list

  curl -Ls https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add -
fi

# export CMAKE_C_COMPILER=clang-13
# export CMAKE_CXX_COMPILER=clang++-13

inf "Install build dependencies"
apt-get update
apt-get install -y time git-core subversion build-essential ccache ecj fastjar file screen quilt libncursesw5-dev libssl-dev \
  g++ java-propose-classpath libelf-dev bash make patch libncurses5 libncurses5-dev zlib1g-dev gawk \
  flex gettext wget unzip xz-utils python python-distutils-extra python3 python3-distutils-extra rsync \
  python3-setuptools python3-dev swig xsltproc zlib1g-dev

apt-get install -y libllvm-13-ocaml-dev libllvm13 llvm-13 llvm-13-dev llvm-13-doc llvm-13-examples llvm-13-runtime

apt-get install -y clang-13 clang-tools-13 clang-13-doc libclang-common-13-dev libclang-13-dev libclang1-13 clang-format-13 python3-clang-13 clangd-13 clang-tidy-13

apt-get install -y lldb-13 lld-13

if [[ ${IMAGE_BUILD_ONLY:-false} == false ]]; then
  USER_ID=${USER_ID:-1000}
  GROUP_ID=${GROUP_ID:-1000}
  ARTIFACTS_PATH=${ARTIFACTS_PATH:-/tmp/artifacts}
  OPENWRT_PATH=${OPENWRT_PATH:-/tmp/openwrt}

  inf "USER_ID=$USER_ID"
  inf "GROUP_ID=$GROUP_ID"
  inf "ARTIFACTS_PATH=$ARTIFACTS_PATH"
  inf "OPENWRT_PATH=$OPENWRT_PATH"

  inf "Creating buser - build user"
  groupadd --gid "$GROUP_ID" buser
  useradd --uid "$USER_ID" --gid "$GROUP_ID" -m -s /bin/bash buser

  mkdir -p "$ARTIFACTS_PATH"
  mkdir -p "$OPENWRT_PATH"

  chown -R "$USER_ID":"$GROUP_ID" "$SCRIPT_PATH"
  chown -R "$USER_ID":"$GROUP_ID" "$OPENWRT_PATH"

  inf "Run ./build_image.sh"
  # IN_DOCKER=true ./build_image.sh
  su -c "OPENWRT_PATH=$OPENWRT_PATH IN_DOCKER=true ./build_image.sh" buser
  build_exitcode=$?

  inf "Copy artifacts to ARTIFACTS_PATH"
  cd "$OPENWRT_PATH"

  # shellcheck disable=SC2046
  cp -rfv $(find . | grep bin/targets | grep -i ax6s) "$ARTIFACTS_PATH/"
  # shellcheck disable=SC2046
  cp -rfv $(find . | grep bin/targets | grep -i profiles.json) "$ARTIFACTS_PATH/"
  # shellcheck disable=SC2046
  cp -rfv $(find . | grep bin/targets | grep -i sha256sum) "$ARTIFACTS_PATH/"
  cp -rfv "$OPENWRT_PATH"/upstream/.config "$ARTIFACTS_PATH/config.build"
  cp -rfv "$OPENWRT_PATH"/files/ax3200_78a9bee.patch "$ARTIFACTS_PATH/"
  cp -rfv "$SCRIPT_PATH"/files/config.buildinfo "$ARTIFACTS_PATH/config.buildinfo"

  sha256sum "$ARTIFACTS_PATH"/* > "$ARTIFACTS_PATH/sha256sums_artifacts_only"
  exit $build_exitcode
fi
