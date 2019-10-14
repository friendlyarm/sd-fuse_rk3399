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
wget http://${HTTP_SERVER}/dvdfiles/rk3399/images-for-eflasher/friendlycore-arm64-images.tgz
tar xzf friendlycore-arm64-images.tgz
wget http://${HTTP_SERVER}/dvdfiles/rk3399/images-for-eflasher/emmc-flasher-images.tgz
tar xzf emmc-flasher-images.tgz
wget http://${HTTP_SERVER}/dvdfiles/rk3399/rootfs/rootfs-friendlycore-arm64.tgz
tar xzf rootfs-friendlycore-arm64.tgz
echo hello > friendlycore-arm64/rootfs/root/welcome.txt
(cd friendlycore-arm64/rootfs/root/ && {
	wget http://${HTTP_SERVER}/dvdfiles/rk3399/images-for-eflasher/friendlycore-arm64-images.tgz -O deleteme.tgz
});
./build-rootfs-img.sh friendlycore-arm64/rootfs friendlycore-arm64
sudo ./mk-sd-image.sh friendlycore-arm64
sudo ./mk-emmc-image.sh friendlycore-arm64
