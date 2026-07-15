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
git clone ../../.git sd-fuse_rk3399
cd sd-fuse_rk3399

wget ${CDN_URL}/ubuntu-noble-core-arm64-images.tgz
tar xzf ubuntu-noble-core-arm64-images.tgz

wget ${CDN_URL}/openmediavault-arm64-images.tgz
tar xzf openmediavault-arm64-images.tgz

wget ${CDN_URL}/emmc-flasher-images.tgz
tar xzf emmc-flasher-images.tgz


./mk-sd-image.sh ubuntu-noble-core-arm64
./mk-emmc-image.sh ubuntu-noble-core-arm64

./mk-sd-image.sh openmediavault-arm64
./mk-emmc-image.sh openmediavault-arm64

./mk-emmc-image.sh ubuntu-noble-core-arm64 filename=ubuntu-noble-core-auto-eflasher.img autostart=yes

wget ${CDN_URL}/friendlywrt25-images.tgz
tar xzf friendlywrt25-images.tgz

wget ${CDN_URL}/friendlywrt25-docker-images.tgz
tar xzf friendlywrt25-docker-images.tgz

./mk-sd-image.sh friendlywrt25
./mk-emmc-image.sh friendlywrt25 autostart=yes

./mk-sd-image.sh friendlywrt25-docker
./mk-emmc-image.sh friendlywrt25-docker autostart=yes

echo "done."
