#!/bin/bash
set -eux

HTTP_SERVER=112.124.9.243
UBOOT_REPO=https://github.com/friendlyarm/uboot-rockchip
UBOOT_BRANCH=nanopi4-v2017.09

# hack for me
[ -f /etc/friendlyarm ] && source /etc/friendlyarm $(basename $(builtin cd ..; pwd))

# clean
mkdir -p tmp
sudo rm -rf tmp/*

cd tmp
git clone ../../.git sd-fuse_rk3399
cd sd-fuse_rk3399
if [ -f ../../friendlycore-lite-noble-arm64-images.tgz ]; then
	tar xvzf ../../friendlycore-lite-noble-arm64-images.tgz
else
	wget --no-proxy http://${HTTP_SERVER}/dvdfiles/RK3399/images-for-eflasher/friendlycore-lite-noble-arm64-images.tgz
    tar xvzf friendlycore-lite-noble-arm64-images.tgz
fi

git clone ${UBOOT_REPO} --depth 1 -b ${UBOOT_BRANCH} uboot-rk3399

UBOOT_SRC=$PWD/uboot-rk3399 ./build-uboot.sh friendlycore-lite-noble-arm64
./mk-sd-image.sh friendlycore-lite-noble-arm64
