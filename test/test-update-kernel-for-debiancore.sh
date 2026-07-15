#!/bin/bash
set -eu

if [ -f "$(dirname "$(readlink -f "$0")")/../.use-local-r2" ]; then
    CDN_URL=http://cdn.local/friendlyelec-cdn/os-images/rk3399/images
else
    CDN_URL=https://downloads.friendlyelec.com/os-images/rk3399/images
fi
KERNEL_URL=https://github.com/friendlyarm/kernel-rockchip
KERNEL_BRANCH=nanopi-r2-v6.6.y

# clean
mkdir -p tmp
sudo rm -rf tmp/*

cd tmp
git clone ../../.git sd-fuse_rk3399
cd sd-fuse_rk3399

# hack for me
[ -f /etc/friendlyarm ] && source /etc/friendlyarm $(basename $(builtin cd ..; pwd))

if [ -f ../../debian-trixie-core-arm64-images.tgz ]; then
	tar xvzf ../../debian-trixie-core-arm64-images.tgz
else
	wget ${CDN_URL}/debian-trixie-core-arm64-images.tgz
    tar xvzf debian-trixie-core-arm64-images.tgz
fi

wget ${CDN_URL}/emmc-flasher-images.tgz
tar xzf emmc-flasher-images.tgz

if [ -f ../../kernel-rk3399.tgz ]; then
	tar xvzf ../../kernel-rk3399.tgz
else
	git clone ${KERNEL_URL} --depth 1 -b ${KERNEL_BRANCH} kernel-rk3399
fi

wget http://112.124.9.243/sd-fuse/kernel-3rd-drivers.tgz
if [ -f kernel-3rd-drivers.tgz ]; then
    pushd out
    tar xzf ../kernel-3rd-drivers.tgz
    popd
fi

KERNEL_SRC=$PWD/kernel-rk3399 ./build-kernel.sh debian-trixie-core-arm64
cp prebuilt/dtbo.img debian-trixie-core-arm64
sudo ./mk-sd-image.sh debian-trixie-core-arm64
sudo ./mk-emmc-image.sh debian-trixie-core-arm64 autostart=yes
