#!/bin/bash
set -eu

HTTP_SERVER=112.124.9.243
KERNEL_URL=https://github.com/friendlyarm/kernel-rockchip
KERNEL_BRANCH=nanopi5-v5.10.y_opt

# hack for me
[ -f /etc/friendlyarm ] && source /etc/friendlyarm $(basename $(builtin cd ..; pwd))

# clean
mkdir -p tmp
sudo rm -rf tmp/*

cd tmp
git clone ../../.git -b kernel-5.10.y sd-fuse_rk3399
cd sd-fuse_rk3399
if [ -f ../../debian-buster-desktop-arm64-images.tgz ]; then
	tar xvzf ../../debian-buster-desktop-arm64-images.tgz
else
	wget --no-proxy http://${HTTP_SERVER}/dvdfiles/RK3568/images-for-eflasher/debian-buster-desktop-arm64-images.tgz
    tar xvzf debian-buster-desktop-arm64-images.tgz
fi

if [ -f ../../kernel-rk3399.tgz ]; then
	tar xvzf ../../kernel-rk3399.tgz
else
	git clone ${KERNEL_URL} --depth 1 -b ${KERNEL_BRANCH} kernel-rk3399
fi

wget http://${HTTP_SERVER}/sd-fuse/kernel-3rd-drivers.tgz
if [ -f kernel-3rd-drivers.tgz ]; then
    pushd out
    tar xzf ../kernel-3rd-drivers.tgz
    popd
fi

MK_HEADERS_DEB=1 BUILD_THIRD_PARTY_DRIVER=1 KERNEL_SRC=$PWD/kernel-rk3399 ./build-kernel.sh debian-buster-desktop-arm64
