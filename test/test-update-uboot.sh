#!/bin/bash
set -eux

if [ -f "$(dirname "$(readlink -f "$0")")/../.use-local-r2" ]; then
    CDN_URL=http://cdn.local/friendlyelec-cdn/os-images/rk3399/images
else
    CDN_URL=https://downloads.friendlyelec.com/os-images/rk3399/images
fi
UBOOT_URL=https://github.com/friendlyarm/uboot-rockchip
UBOOT_BRANCH=nanopi4-v2017.09

# hack for me
[ -f /etc/friendlyarm ] && source /etc/friendlyarm $(basename $(builtin cd ..; pwd))

# clean
mkdir -p tmp
sudo rm -rf tmp/*

cd tmp
git clone ../../.git -b kernel-4.19 sd-fuse_rk3399
cd sd-fuse_rk3399
if [ -f ../../friendlycore-focal-arm64-images.tgz ]; then
	tar xvzf ../../friendlycore-focal-arm64-images.tgz
else
	wget ${CDN_URL}/friendlycore-focal-arm64-images.tgz
	tar xvzf friendlycore-focal-arm64-images.tgz
fi

git clone ${UBOOT_URL} --depth 1 -b ${UBOOT_BRANCH} uboot-rk3399
UBOOT_SRC=$PWD/uboot-rk3399 ./build-uboot.sh friendlycore-focal-arm64
./mk-sd-image.sh friendlycore-focal-arm64
