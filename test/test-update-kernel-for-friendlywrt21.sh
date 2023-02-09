#!/bin/bash
set -eu

HTTP_SERVER=112.124.9.243
KERNEL_URL=https://github.com/friendlyarm/kernel-rockchip
KERNEL_BRANCH=nanopi4-v4.19.y

# hack for me
PCNAME=`hostname`
if [ x"${PCNAME}" = x"tzs-i7pc" ]; then
	HTTP_SERVER=127.0.0.1
	KERNEL_URL=git@192.168.1.5:/devel/kernel/linux.git
	KERNEL_BRANCH=nanopi4-v4.19.y
fi

# clean
mkdir -p tmp
sudo rm -rf tmp/*

cd tmp
git clone ../../.git sd-fuse_rk3399
cd sd-fuse_rk3399
if [ -f ../../friendlywrt21-kernel4-images.tgz ]; then
	tar xvzf ../../friendlywrt21-kernel4-images.tgz
else
	wget --no-proxy http://${HTTP_SERVER}/dvdfiles/RK3399/images-for-eflasher/friendlywrt21-kernel4-images.tgz
    tar xvzf friendlywrt21-kernel4-images.tgz
fi

if [ -f ../../kernel-rk3399-4.19.tgz ]; then
	tar xvzf ../../kernel-rk3399-4.19.tgz
else
	git clone ${KERNEL_URL} --depth 1 -b ${KERNEL_BRANCH} kernel-rk3399-4.19
fi

BUILD_THIRD_PARTY_DRIVER=0 KERNEL_SRC=$PWD/kernel-rk3399-4.19 ./build-kernel.sh friendlywrt21-kernel4
sudo ./mk-sd-image.sh friendlywrt21-kernel4