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
if [ -f ../../friendlywrt22-images.tgz ]; then
	tar xvzf ../../friendlywrt22-images.tgz
else
	wget --no-proxy http://${HTTP_SERVER}/dvdfiles/RK3399/images-for-eflasher/friendlywrt22-images.tgz
    tar xvzf friendlywrt22-images.tgz
fi

if [ -f ../../kernel-rk3399-5.15.tgz ]; then
	tar xvzf ../../kernel-rk3399-5.15.tgz
else
	git clone ${KERNEL_URL} --depth 1 -b ${KERNEL_BRANCH} kernel-rk3399-5.15
fi

BUILD_THIRD_PARTY_DRIVER=0 KERNEL_SRC=$PWD/kernel-rk3399-5.15 ./build-kernel.sh friendlywrt22
sudo ./mk-sd-image.sh friendlywrt22
