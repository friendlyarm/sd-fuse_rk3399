#!/bin/bash
set -eux

if [ -f "$(dirname "$(readlink -f "$0")")/../.use-local-r2" ]; then
    CDN_URL=http://cdn.local/friendlyelec-cdn/os-images/rk3399/images
    ROOTFS_URL=http://cdn.local/friendlyelec-cdn/rootfs/rk3399
else
    CDN_URL=https://downloads.friendlyelec.com/os-images/rk3399/images
    ROOTFS_URL=https://downloads.friendlyelec.com/rootfs/rk3399
fi
# hack for me
[ -f /etc/friendlyarm ] && source /etc/friendlyarm $(basename $(builtin cd ..; pwd))

# clean
mkdir -p tmp
sudo rm -rf tmp/*

cd tmp
git clone ../../.git -b kernel-4.19 sd-fuse_rk3399
cd sd-fuse_rk3399
git checkout kernel-4.19
wget ${CDN_URL}/friendlycore-focal-arm64-images.tgz
tar xzf friendlycore-focal-arm64-images.tgz
wget ${CDN_URL}/emmc-flasher-images.tgz
tar xzf emmc-flasher-images.tgz
wget ${ROOTFS_URL}/rootfs-friendlycore-focal-arm64.tgz
wget ${ROOTFS_URL}/rootfs-friendlycore-focal-arm64.tgz.sha256
sha256sum -c rootfs-friendlycore-focal-arm64.tgz.sha256
tar xzf rootfs-friendlycore-focal-arm64.tgz
echo hello > friendlycore-focal-arm64/rootfs/root/welcome.txt
(cd friendlycore-focal-arm64/rootfs/root/ && {
	wget ${CDN_URL}/friendlycore-focal-arm64-images.tgz -O deleteme.tgz
});
./build-rootfs-img.sh friendlycore-focal-arm64/rootfs friendlycore-focal-arm64
./mk-sd-image.sh friendlycore-focal-arm64
./mk-emmc-image.sh friendlycore-focal-arm64
