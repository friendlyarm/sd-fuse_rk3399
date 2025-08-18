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

wget --no-proxy http://${HTTP_SERVER}/dvdfiles/RK3399/images-for-eflasher/friendlydesktop-arm64-images.tgz
tar xzf friendlydesktop-arm64-images.tgz
cp prebuilt/param4sd-plain.txt friendlydesktop-arm64/sd-boot/param4sd.txt
cp prebuilt/partmap-plain.txt friendlydesktop-arm64/sd-boot/partmap.txt
sudo ./mk-sd-image.sh friendlydesktop-arm64

echo "done."
