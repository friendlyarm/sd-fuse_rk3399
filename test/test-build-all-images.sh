#!/bin/bash
set -eu

HTTP_SERVER=112.124.9.243

# hack for me
PCNAME=`hostname`
if [ x"${PCNAME}" = x"tzs-i7pc" ]; then
       HTTP_SERVER=127.0.0.1
fi

# clean
mkdir -p tmp
sudo rm -rf tmp/*

cd tmp
git clone ../../.git -b kernel-5.15.y sd-fuse_rk3399
cd sd-fuse_rk3399


wget --no-proxy http://${HTTP_SERVER}/dvdfiles/rk3399/images-for-eflasher/friendlycore-lite-focal-kernel6-arm64-images.tgz
tar xzf friendlycore-lite-focal-kernel6-arm64-images.tgz

wget --no-proxy http://${HTTP_SERVER}/dvdfiles/rk3399/images-for-eflasher/openmediavault-arm64-images.tgz
tar xzf openmediavault-arm64-images.tgz

wget --no-proxy http://${HTTP_SERVER}/dvdfiles/rk3399/images-for-eflasher/friendlywrt23-images.tgz
tar xzf friendlywrt23-images.tgz

wget --no-proxy http://${HTTP_SERVER}/dvdfiles/rk3399/images-for-eflasher/friendlywrt21-images.tgz
tar xzf friendlywrt21-images.tgz

wget --no-proxy http://${HTTP_SERVER}/dvdfiles/rk3399/images-for-eflasher/emmc-flasher-images.tgz
tar xzf emmc-flasher-images.tgz


./mk-sd-image.sh friendlycore-lite-focal-kernel6-arm64
./mk-emmc-image.sh friendlycore-lite-focal-kernel6-arm64

./mk-sd-image.sh openmediavault-arm64
./mk-emmc-image.sh openmediavault-arm64

./mk-sd-image.sh friendlywrt23
./mk-emmc-image.sh friendlywrt23

./mk-sd-image.sh friendlywrt21
./mk-emmc-image.sh friendlywrt21


./mk-emmc-image.sh friendlycore-lite-focal-kernel6-arm64 filename=friendlycore-lite-focal-auto-eflasher.img autostart=yes

echo "done."
