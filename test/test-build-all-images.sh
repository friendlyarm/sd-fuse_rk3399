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
git clone ../../.git -b kernel-4.19 sd-fuse_rk3399
cd sd-fuse_rk3399

wget http://${HTTP_SERVER}/dvdfiles/rk3399/images-for-eflasher/friendlycore-focal-arm64-images.tgz
tar xzf friendlycore-focal-arm64-images.tgz

wget http://${HTTP_SERVER}/dvdfiles/rk3399/images-for-eflasher/friendlycore-lite-focal-kernel4-arm64-images.tgz
tar xzf friendlycore-lite-focal-kernel4-arm64-images.tgz

wget http://${HTTP_SERVER}/dvdfiles/rk3399/images-for-eflasher/friendlywrt-kernel4-images.tgz
tar xzf friendlywrt-kernel4-images.tgz

wget http://${HTTP_SERVER}/dvdfiles/rk3399/images-for-eflasher/android-10-images.tgz
tar xzf android-10-images.tgz

wget http://${HTTP_SERVER}/dvdfiles/rk3399/images-for-eflasher/emmc-flasher-images.tgz
tar xzf emmc-flasher-images.tgz

./mk-sd-image.sh friendlycore-focal-arm64
./mk-emmc-image.sh friendlycore-focal-arm64

./mk-sd-image.sh friendlycore-lite-focal-kernel4-arm64
./mk-emmc-image.sh friendlycore-lite-focal-kernel4-arm64

./mk-sd-image.sh friendlywrt-kernel4
./mk-emmc-image.sh friendlywrt-kernel4

./mk-sd-image.sh android10
./mk-emmc-image.sh android10

./mk-emmc-image.sh friendlycore-focal-arm64 filename=friendlycore-focal-auto-eflasher.img autostart=yes

echo "done."