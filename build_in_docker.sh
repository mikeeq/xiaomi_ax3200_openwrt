#!/usr/bin/env bash

RUN_PATH=$PWD
SCRIPT_PATH=${SCRIPT_PATH:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

echo "===]> Info: RUN_PATH=$RUN_PATH"
echo "===]> Info: SCRIPT_PATH=$SCRIPT_PATH"

pwd
echo "CPU threads: $(nproc --all)"
grep 'model name' /proc/cpuinfo | uniq

cd $SCRIPT_PATH

USERID=1000
GROUPID=1000

chown -R $USERID:$GROUPID $SCRIPT_PATH

apt-get update && \
apt-get install -y sudo curl vim gnupg

# echo "
# deb http://apt.llvm.org/buster/ llvm-toolchain-buster-12 main
# deb-src http://apt.llvm.org/buster/ llvm-toolchain-buster-12 main" >> /etc/apt/sources.list

# curl -Ls https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add -

# export CMAKE_C_COMPILER=clang-12
# export CMAKE_CXX_COMPILER=clang++-12

apt-get update && \
apt-get install -y time git-core subversion build-essential ccache ecj fastjar file screen quilt libncursesw5-dev libssl-dev \
  g++ java-propose-classpath libelf-dev bash make patch libncurses5 libncurses5-dev zlib1g-dev gawk \
  flex gettext wget unzip xz-utils python3 python3-distutils-extra rsync \
  python3-setuptools python3-dev swig xsltproc zlib1g-dev llvm clang-12 && \
apt-get clean && \
groupadd --gid $GROUPID buser && \
useradd --uid $USERID --gid $GROUPID -m -s /bin/bash buser

echo "===]> Info: Run ./build.sh"
# IN_DOCKER=true ./build.sh
su -c "IN_DOCKER=true ./build.sh" buser
