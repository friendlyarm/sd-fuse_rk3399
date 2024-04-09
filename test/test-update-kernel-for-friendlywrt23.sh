#!/bin/bash
set -eu

HTTP_SERVER=112.124.9.243
KERNEL_URL=https://github.com/friendlyarm/kernel-rockchip
KERNEL_BRANCH=nanopi-r2-v6.1.y

# hack for me
[ -f /etc/friendlyarm ] && source /etc/friendlyarm $(basename $(builtin cd ..; pwd))

# clean
mkdir -p tmp
sudo rm -rf tmp/*

cd tmp
git clone ../../.git sd-fuse_rk3399
cd sd-fuse_rk3399
if [ -f ../../friendlywrt23-images.tgz ]; then
	tar xvzf ../../friendlywrt23-images.tgz
else
	wget --no-proxy http://${HTTP_SERVER}/dvdfiles/RK3399/images-for-eflasher/friendlywrt23-images.tgz
    tar xvzf friendlywrt23-images.tgz
fi

if [ -f ../../kernel-rk3399-5.15.tgz ]; then
	tar xvzf ../../kernel-rk3399-5.15.tgz
else
	git clone ${KERNEL_URL} --depth 1 -b ${KERNEL_BRANCH} kernel-rk3399-5.15
fi

wget http://${HTTP_SERVER}/sd-fuse/kernel-3rd-drivers.tgz
if [ -f kernel-3rd-drivers.tgz ]; then
    pushd out
    tar xzf ../kernel-3rd-drivers.tgz
    popd
fi

KERNEL_SRC=$PWD/kernel-rk3399-5.15 ./build-kernel.sh friendlywrt23
sudo ./mk-sd-image.sh friendlywrt23
