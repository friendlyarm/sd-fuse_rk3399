#!/bin/bash
set -eux

HTTP_SERVER=112.124.9.243

# hack for me
PCNAME=`hostname`
if [ x"${PCNAME}" = x"tzs-i7pc" ]; then
       HTTP_SERVER=192.168.1.9
fi

# clean
mkdir -p tmp
sudo rm -rf tmp/*

cd tmp
git clone ../../.git sd-fuse_rk3399
cd sd-fuse_rk3399
wget http://${HTTP_SERVER}/dvdfiles/rk3399/images-for-eflasher/friendlycore-lite-focal-kernel5-arm64-images.tgz
tar xzf friendlycore-lite-focal-kernel5-arm64-images.tgz
wget http://${HTTP_SERVER}/dvdfiles/rk3399/images-for-eflasher/emmc-flasher-images.tgz
tar xzf emmc-flasher-images.tgz

# make big file
fallocate -l 6G friendlycore-lite-focal-kernel5-arm64/rootfs.img

# calc image size
IMG_SIZE=`du -s -B 1 friendlycore-lite-focal-kernel5-arm64/rootfs.img | cut -f1`

# re-gen parameter.txt
./tools/generate-partmap-txt.sh ${IMG_SIZE} friendlycore-lite-focal-kernel5-arm64

./mk-sd-image.sh friendlycore-lite-focal-kernel5-arm64
sudo ./mk-emmc-image.sh friendlycore-lite-focal-kernel5-arm64
