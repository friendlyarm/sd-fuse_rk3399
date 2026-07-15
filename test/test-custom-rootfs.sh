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
git clone ../../.git sd-fuse_rk3399
cd sd-fuse_rk3399
wget ${CDN_URL}/friendlycore-arm64-images.tgz
tar xzf friendlycore-arm64-images.tgz
wget ${CDN_URL}/emmc-flasher-images.tgz
tar xzf emmc-flasher-images.tgz
wget ${ROOTFS_URL}/rootfs-friendlycore-arm64.tgz
wget ${ROOTFS_URL}/rootfs-friendlycore-arm64.tgz.sha256
sha256sum -c rootfs-friendlycore-arm64.tgz.sha256
tar xzf rootfs-friendlycore-arm64.tgz
echo hello > friendlycore-arm64/rootfs/root/welcome.txt
(cd friendlycore-arm64/rootfs/root/ && {
	wget ${CDN_URL}/friendlycore-arm64-images.tgz -O deleteme.tgz
});
./build-rootfs-img.sh friendlycore-arm64/rootfs friendlycore-arm64
sudo ./mk-sd-image.sh friendlycore-arm64
sudo ./mk-emmc-image.sh friendlycore-arm64
