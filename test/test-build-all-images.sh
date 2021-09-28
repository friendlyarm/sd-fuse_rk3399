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
git clone ../../.git -b kernel-5.10.y sd-fuse_rk3399
cd sd-fuse_rk3399


wget http://${HTTP_SERVER}/dvdfiles/rk3399/images-for-eflasher/friendlycore-lite-focal-kernel5-arm64-images.tgz
tar xzf friendlycore-lite-focal-kernel5-arm64-images.tgz

wget http://${HTTP_SERVER}/dvdfiles/rk3399/images-for-eflasher/friendlywrt-images.tgz
tar xzf friendlywrt-images.tgz

wget http://${HTTP_SERVER}/dvdfiles/rk3399/images-for-eflasher/emmc-flasher-images.tgz
tar xzf emmc-flasher-images.tgz


sudo ./mk-sd-image.sh friendlycore-lite-focal-kernel5-arm64
sudo ./mk-emmc-image.sh friendlycore-lite-focal-kernel5-arm64

sudo ./mk-sd-image.sh friendlywrt
sudo ./mk-emmc-image.sh friendlywrt

sudo ./mk-emmc-image.sh friendlycore-lite-focal-kernel5-arm64 filename=friendlycore-lite-focal-auto-eflasher.img autostart=yes

echo "done."
