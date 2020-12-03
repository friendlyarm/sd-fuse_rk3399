#!/bin/bash
set -eux

HTTP_SERVER=112.124.9.243
UBOOT_URL=https://github.com/friendlyarm/uboot-rockchip
UBOOT_BRANCH=nanopi4-v2017.09

# hack for me
PCNAME=`hostname`
if [ x"${PCNAME}" = x"tzs-i7pc" ]; then
	HTTP_SERVER=192.168.1.9
fi

# clean
mkdir -p tmp
sudo rm -rf tmp/*

cd tmp
git clone ../../.git -b kernel-4.19 sd-fuse_rk3399
cd sd-fuse_rk3399
if [ -f ../../friendlycore-focal-arm64-images.tgz ]; then
	tar xvzf ../../friendlycore-focal-arm64-images.tgz
else
	wget http://${HTTP_SERVER}/dvdfiles/rk3399/images-for-eflasher/friendlycore-focal-arm64-images.tgz
	tar xvzf friendlycore-focal-arm64-images.tgz
fi

[ -d rkbin ] || git clone https://github.com/friendlyarm/rkbin

git clone ${UBOOT_URL} --depth 1 -b ${UBOOT_BRANCH} uboot-rk3399
(cd rkbin && git reset 25de1a8bffb1e971f1a69d1aa4bc4f9e3d352ea3 --hard)
UBOOT_SRC=$PWD/uboot-rk3399 ./build-uboot.sh friendlycore-focal-arm64
sudo ./mk-sd-image.sh friendlycore-focal-arm64
