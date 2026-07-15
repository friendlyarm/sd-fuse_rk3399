#!/bin/bash
set -eu

if [ -f "$(dirname "$(readlink -f "$0")")/../.use-local-r2" ]; then
    CDN_URL=http://cdn.local/friendlyelec-cdn/os-images/rk3399/images
else
    CDN_URL=https://downloads.friendlyelec.com/os-images/rk3399/images
fi
# hack for me
[ -f /etc/friendlyarm ] && source /etc/friendlyarm $(basename $(builtin cd ..; pwd))

# clean
mkdir -p tmp
sudo rm -rf tmp/*

cd tmp
git clone ../../.git -b master sd-fuse_rk3399
cd sd-fuse_rk3399

wget ${CDN_URL}/friendlycore-arm64-images.tgz
tar xzf friendlycore-arm64-images.tgz

wget ${CDN_URL}/friendlydesktop-arm64-images.tgz
tar xzf friendlydesktop-arm64-images.tgz

wget ${CDN_URL}/lubuntu-desktop-images.tgz
tar xzf lubuntu-desktop-images.tgz

wget ${CDN_URL}/android-nougat-images.tgz
tar xzf android-nougat-images.tgz

wget ${CDN_URL}/android-oreo-images.tgz
tar xzf android-oreo-images.tgz

wget ${CDN_URL}/emmc-flasher-images.tgz
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
