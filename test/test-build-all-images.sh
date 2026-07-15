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
git clone ../../.git -b kernel-4.19 sd-fuse_rk3399
cd sd-fuse_rk3399

wget ${CDN_URL}/friendlycore-focal-arm64-images.tgz
tar xzf friendlycore-focal-arm64-images.tgz

wget ${CDN_URL}/debian-bullseye-desktop-arm64-images.tgz
tar xzf debian-bullseye-desktop-arm64-images.tgz

wget ${CDN_URL}/ubuntu-noble-core-arm64-images.tgz
tar xzf ubuntu-noble-core-arm64-images.tgz

wget ${CDN_URL}/openmediavault-arm64-images.tgz
tar xzf openmediavault-arm64-images.tgz

wget ${CDN_URL}/android-10-images.tgz
tar xzf android-10-images.tgz

wget ${CDN_URL}/buildroot-images.tgz
tar xzf buildroot-images.tgz

wget ${CDN_URL}/emmc-flasher-images.tgz
tar xzf emmc-flasher-images.tgz

./mk-sd-image.sh friendlycore-focal-arm64
./mk-emmc-image.sh friendlycore-focal-arm64

./mk-sd-image.sh debian-bullseye-desktop-arm64
./mk-emmc-image.sh debian-bullseye-desktop-arm64

./mk-sd-image.sh ubuntu-noble-core-arm64
./mk-emmc-image.sh ubuntu-noble-core-arm64

./mk-sd-image.sh openmediavault-arm64
./mk-emmc-image.sh openmediavault-arm64

./mk-sd-image.sh android10
./mk-emmc-image.sh android10

./mk-sd-image.sh buildroot
./mk-emmc-image.sh buildroot

./mk-emmc-image.sh openmediavault-arm64 filename=openmediavault-auto-eflasher.img autostart=yes

echo "done."
