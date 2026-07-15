#!/bin/bash
set -eu

if [ -f "$(dirname "$(readlink -f "$0")")/../.use-local-r2" ]; then
    CDN_URL=http://cdn.local/friendlyelec-cdn/os-images/rk3399/images
    ROOTFS_URL=http://cdn.local/friendlyelec-cdn/rootfs/rk3399
else
    CDN_URL=https://downloads.friendlyelec.com/os-images/rk3399/images
    ROOTFS_URL=https://downloads.friendlyelec.com/rootfs/rk3399
fi
KERNEL_URL=https://github.com/friendlyarm/kernel-rockchip
KERNEL_BRANCH=nanopi-r2-v6.1.y
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
wget ${CDN_URL}/debian-trixie-core-arm64-images.tgz
tar xzf debian-trixie-core-arm64-images.tgz
wget ${CDN_URL}/emmc-flasher-images.tgz
tar xzf emmc-flasher-images.tgz
wget ${ROOTFS_URL}/rootfs-debian-trixie-core-arm64.tgz
wget ${ROOTFS_URL}/rootfs-debian-trixie-core-arm64.tgz.sha256
sha256sum -c rootfs-debian-trixie-core-arm64.tgz.sha256

# build kernel to add btrfs config 
[ -d kernel ] || git clone ${KERNEL_URL} --depth 1 -b ${KERNEL_BRANCH} kernel
echo "CONFIG_BTRFS_FS=y" >> kernel/arch/arm64/configs/${KCFG}
BUILD_THIRD_PARTY_DRIVER=1 KERNEL_SRC=$PWD/kernel ./build-kernel.sh debian-trixie-core-arm64

# update kernel modules to rootfs
sudo ./tools/extract-rootfs-tar.sh rootfs-debian-trixie-core-arm64.tgz
sudo rm -rf debian-trixie-core-arm64/rootfs/lib/modules/*
sudo rsync -a out/output_${SOC}_kmodules/lib/modules/* debian-trixie-core-arm64/rootfs/lib/modules/

# create rootfs.img with btrfs
sudo -E FS_TYPE=btrfs ./build-rootfs-img.sh debian-trixie-core-arm64/rootfs debian-trixie-core-arm64

./mk-sd-image.sh debian-trixie-core-arm64
./mk-emmc-image.sh debian-trixie-core-arm64 autostart=yes
