#!/bin/bash
set -eux

HTTP_SERVER=112.124.9.243

# hack for me
[ -f /etc/friendlyarm ] && source /etc/friendlyarm $(basename $(builtin cd ..; pwd))

# clean
mkdir -p tmp
sudo rm -rf tmp/*

cd tmp
git clone ../../.git -b kernel-4.19 sd-fuse_rk3399
cd sd-fuse_rk3399
wget --no-proxy http://${HTTP_SERVER}/dvdfiles/RK3399/images-for-eflasher/ubuntu-focal-desktop-arm64-images.tgz
tar xzf ubuntu-focal-desktop-arm64-images.tgz
wget --no-proxy http://${HTTP_SERVER}/dvdfiles/RK3399/images-for-eflasher/emmc-flasher-images.tgz
tar xzf emmc-flasher-images.tgz

# 20G rootfs
fallocate -l 20G ubuntu-focal-desktop-arm64/rootfs.img

# calc image size
IMG_SIZE=`du -s -B 1 ubuntu-focal-desktop-arm64/rootfs.img | cut -f1`

# re-gen parameter.txt
./tools/generate-partmap-txt.sh ${IMG_SIZE} ubuntu-focal-desktop-arm64

# The image can only be written to a TF card that is 32GB or bigger
RAW_SIZE_MB=30000 ./mk-sd-image.sh ubuntu-focal-desktop-arm64
sudo bash -c 'RAW_SIZE_MB=30000 ./mk-emmc-image.sh ubuntu-focal-desktop-arm64'
