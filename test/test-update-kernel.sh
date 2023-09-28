#!/bin/bash
set -eu

HTTP_SERVER=112.124.9.243
KERNEL_URL=https://github.com/friendlyarm/kernel-rockchip
KERNEL_BRANCH=nanopi-r2-v5.15.y

# hack for me
PCNAME=`hostname`
if [ x"${PCNAME}" = x"tzs-i7pc" ]; then
	HTTP_SERVER=127.0.0.1
	KERNEL_URL=git@192.168.1.5:/devel/kernel/linux.git
	KERNEL_BRANCH=nanopi-r2-v5.15.y
fi

# clean
mkdir -p tmp
sudo rm -rf tmp/*

cd tmp
git clone ../../.git sd-fuse_rk3399
cd sd-fuse_rk3399
if [ -f ../../friendlycore-lite-focal-kernel6-arm64-images.tgz ]; then
	tar xvzf ../../friendlycore-lite-focal-kernel6-arm64-images.tgz
else
	wget --no-proxy http://${HTTP_SERVER}/dvdfiles/rk3399/images-for-eflasher/friendlycore-lite-focal-kernel6-arm64-images.tgz
    tar xvzf friendlycore-lite-focal-kernel6-arm64-images.tgz
fi

if [ -f ../../kernel-rk3399.tgz ]; then
	tar xvzf ../../kernel-rk3399.tgz
else
	git clone ${KERNEL_URL} --depth 1 -b ${KERNEL_BRANCH} kernel-rk3399
fi

KERNEL_SRC=$PWD/kernel-rk3399 ./build-kernel.sh friendlycore-lite-focal-kernel6-arm64
cp prebuilt/dtbo.img friendlycore-lite-focal-kernel6-arm64
./mk-sd-image.sh friendlycore-lite-focal-kernel6-arm64
