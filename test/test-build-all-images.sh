#!/bin/bash
set -eu

HTTP_SERVER=112.124.9.243

# hack for me
[ -f /etc/friendlyarm ] && source /etc/friendlyarm $(basename $(builtin cd ..; pwd))

# clean
mkdir -p tmp
sudo rm -rf tmp/*

cd tmp
git clone ../../.git -b kernel-5.15.y sd-fuse_rk3399
cd sd-fuse_rk3399

wget --no-proxy http://${HTTP_SERVER}/dvdfiles/RK3399/images-for-eflasher/friendlycore-lite-focal-arm64-images.tgz
tar xzf friendlycore-lite-focal-arm64-images.tgz

wget --no-proxy http://${HTTP_SERVER}/dvdfiles/RK3399/images-for-eflasher/openmediavault-arm64-images.tgz
tar xzf openmediavault-arm64-images.tgz

wget --no-proxy http://${HTTP_SERVER}/dvdfiles/RK3399/images-for-eflasher/friendlywrt23-images.tgz
tar xzf friendlywrt23-images.tgz

wget --no-proxy http://${HTTP_SERVER}/dvdfiles/RK3399/images-for-eflasher/friendlywrt21-images.tgz
tar xzf friendlywrt21-images.tgz

wget --no-proxy http://${HTTP_SERVER}/dvdfiles/RK3399/images-for-eflasher/emmc-flasher-images.tgz
tar xzf emmc-flasher-images.tgz


./mk-sd-image.sh friendlycore-lite-focal-arm64
./mk-emmc-image.sh friendlycore-lite-focal-arm64

./mk-sd-image.sh openmediavault-arm64
./mk-emmc-image.sh openmediavault-arm64

./mk-sd-image.sh friendlywrt23
./mk-emmc-image.sh friendlywrt23

./mk-sd-image.sh friendlywrt21
./mk-emmc-image.sh friendlywrt21

./mk-emmc-image.sh friendlycore-lite-focal-arm64 filename=friendlycore-lite-focal-auto-eflasher.img autostart=yes

echo "done."
