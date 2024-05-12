#!/bin/bash
set -eux

HTTP_SERVER=112.124.9.243

# hack for me
[ -f /etc/friendlyarm ] && source /etc/friendlyarm $(basename $(builtin cd ..; pwd))

# clean
mkdir -p tmp
sudo rm -rf tmp/*

cd tmp
git clone ../../.git -b kernel-5.10.y sd-fuse_rk3399
cd sd-fuse_rk3399
git checkout kernel-5.10.y
wget --no-proxy http://${HTTP_SERVER}/dvdfiles/RK3399/images-for-eflasher/debian-buster-desktop-arm64-images.tgz
tar xzf debian-buster-desktop-arm64-images.tgz
wget --no-proxy http://${HTTP_SERVER}/dvdfiles/RK3399/images-for-eflasher/emmc-flasher-images.tgz
tar xzf emmc-flasher-images.tgz
wget --no-proxy http://${HTTP_SERVER}/dvdfiles/RK3399/rootfs/rootfs-debian-buster-desktop-arm64.tgz
tar xzf rootfs-debian-buster-desktop-arm64.tgz
echo hello > debian-buster-desktop-arm64/rootfs/root/welcome.txt
(cd debian-buster-desktop-arm64/rootfs/root/ && {
	wget --no-proxy http://${HTTP_SERVER}/dvdfiles/RK3399/images-for-eflasher/debian-buster-desktop-arm64-images.tgz -O deleteme.tgz
});
./build-rootfs-img.sh debian-buster-desktop-arm64/rootfs debian-buster-desktop-arm64
./mk-sd-image.sh debian-buster-desktop-arm64
./mk-emmc-image.sh debian-buster-desktop-arm64
