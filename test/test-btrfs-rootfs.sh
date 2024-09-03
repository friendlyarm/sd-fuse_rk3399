#!/bin/bash
set -eu

HTTP_SERVER=112.124.9.243
KERNEL_URL=https://github.com/friendlyarm/kernel-rockchip
KERNEL_BRANCH=nanopi4-v4.19.y
KCFG=nanopi4_linux_defconfig

# hack for me
[ -f /etc/friendlyarm ] && source /etc/friendlyarm $(basename $(builtin cd ..; pwd))

SOC=rk3399

# clean
mkdir -p tmp
sudo rm -rf tmp/*

cd tmp
git clone ../../.git sd-fuse
cd sd-fuse
wget --no-proxy http://${HTTP_SERVER}/dvdfiles/${SOC^^}/images-for-eflasher/debian-bookworm-core-arm64-images.tgz
tar xzf debian-bookworm-core-arm64-images.tgz
wget --no-proxy http://${HTTP_SERVER}/dvdfiles/${SOC^^}/images-for-eflasher/emmc-flasher-images.tgz
tar xzf emmc-flasher-images.tgz
wget --no-proxy http://${HTTP_SERVER}/dvdfiles/${SOC^^}/rootfs/rootfs-debian-bookworm-core-arm64.tgz

# build kernel to add btrfs config 
[ -d kernel ] || git clone ${KERNEL_URL} --depth 1 -b ${KERNEL_BRANCH} kernel
echo "CONFIG_BTRFS_FS=y" >> kernel/arch/arm64/configs/${KCFG}
BUILD_THIRD_PARTY_DRIVER=0 KERNEL_SRC=$PWD/kernel ./build-kernel.sh debian-bookworm-core-arm64

# update kernel modules to rootfs
sudo ./tools/extract-rootfs-tar.sh rootfs-debian-bookworm-core-arm64.tgz
sudo rm -rf debian-bookworm-core-arm64/rootfs/lib/modules/*
sudo rsync -a out/output_${SOC}_kmodules/lib/modules/* debian-bookworm-core-arm64/rootfs/lib/modules/

# create rootfs.img with btrfs
sudo -E FS_TYPE=btrfs ./build-rootfs-img.sh debian-bookworm-core-arm64/rootfs debian-bookworm-core-arm64

./mk-sd-image.sh debian-bookworm-core-arm64
./mk-emmc-image.sh debian-bookworm-core-arm64 autostart=yes
