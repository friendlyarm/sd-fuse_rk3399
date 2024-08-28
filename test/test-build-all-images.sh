#!/bin/bash
set -eu

HTTP_SERVER=112.124.9.243

# hack for me
[ -f /etc/friendlyarm ] && source /etc/friendlyarm $(basename $(builtin cd ..; pwd))

# clean
mkdir -p tmp
sudo rm -rf tmp/*

cd tmp
git clone ../../.git -b master sd-fuse_rk3399
cd sd-fuse_rk3399

wget --no-proxy http://${HTTP_SERVER}/dvdfiles/RK3399/images-for-eflasher/friendlycore-arm64-images.tgz
tar xzf friendlycore-arm64-images.tgz

wget --no-proxy http://${HTTP_SERVER}/dvdfiles/RK3399/images-for-eflasher/friendlydesktop-arm64-images.tgz
tar xzf friendlydesktop-arm64-images.tgz

wget --no-proxy http://${HTTP_SERVER}/dvdfiles/RK3399/images-for-eflasher/lubuntu-desktop-images.tgz
tar xzf lubuntu-desktop-images.tgz

wget --no-proxy http://${HTTP_SERVER}/dvdfiles/RK3399/images-for-eflasher/android-nougat-images.tgz
tar xzf android-nougat-images.tgz

wget --no-proxy http://${HTTP_SERVER}/dvdfiles/RK3399/images-for-eflasher/android-oreo-images.tgz
tar xzf android-oreo-images.tgz

wget --no-proxy http://${HTTP_SERVER}/dvdfiles/RK3399/images-for-eflasher/emmc-flasher-images.tgz
tar xzf emmc-flasher-images.tgz

sudo ./mk-sd-image.sh friendlycore-arm64
sudo ./mk-emmc-image.sh friendlycore-arm64

sudo ./mk-sd-image.sh friendlydesktop-arm64
sudo ./mk-emmc-image.sh friendlydesktop-arm64

# android7 does not support boot from sd-card
sudo ./mk-emmc-image.sh android7
# android8 does not support boot from sd-card
sudo ./mk-emmc-image.sh android8

sudo ./mk-sd-image.sh lubuntu
sudo ./mk-emmc-image.sh lubuntu

sudo ./mk-emmc-image.sh friendlydesktop-arm64 filename=friendlydesktop-auto-eflasher.img autostart=yes

echo "done."
