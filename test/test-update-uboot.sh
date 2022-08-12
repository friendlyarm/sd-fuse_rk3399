#!/bin/bash
set -eux

HTTP_SERVER=112.124.9.243
UBOOT_URL=https://github.com/friendlyarm/uboot-rockchip
UBOOT_BRANCH=nanopi4-v2017.09

# hack for me
PCNAME=`hostname`
if [ x"${PCNAME}" = x"tzs-i7pc" ]; then
	HTTP_SERVER=127.0.0.1
fi

# clean
mkdir -p tmp
sudo rm -rf tmp/*

cd tmp
git clone ../../.git -b kernel-5.10.y sd-fuse_rk3399
cd sd-fuse_rk3399
if [ -f ../../debian-buster-desktop-arm64-images.tgz ]; then
	tar xvzf ../../debian-buster-desktop-arm64-images.tgz
else
	wget --no-proxy http://${HTTP_SERVER}/dvdfiles/RK3399/images-for-eflasher/debian-buster-desktop-arm64-images.tgz
	tar xvzf debian-buster-desktop-arm64-images.tgz
fi

git clone ${UBOOT_URL} --depth 1 -b ${UBOOT_BRANCH} uboot-rk3399
UBOOT_SRC=$PWD/uboot-rk3399 ./build-uboot.sh debian-buster-desktop-arm64
./mk-sd-image.sh debian-buster-desktop-arm64
