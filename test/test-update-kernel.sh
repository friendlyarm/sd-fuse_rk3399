#!/bin/bash
set -eux

# HTTP_SERVER=112.124.9.243
HTTP_SERVER=192.168.1.9

# clean
mkdir -p tmp
sudo rm -rf tmp/*

cd tmp
git clone ../../.git sd-fuse_rk3399
cd sd-fuse_rk3399
wget http://${HTTP_SERVER}/dvdfiles/rk3399/images-for-eflasher/friendlycore-arm64-images.tgz
tar xzf friendlycore-arm64-images.tgz

# git clone https://github.com/friendlyarm/kernel-rockchip --depth 1 -b nanopi4-linux-v4.4.y kernel-rk3399
git clone git@192.168.1.5:/devel/kernel/linux.git --depth 1 -b nanopi4-linux-v4.4.y kernel-rk3399

KERNEL_SRC=$PWD/kernel-rk3399 ./build-kernel.sh friendlycore-arm64
sudo ./mk-sd-image.sh friendlycore-arm64
