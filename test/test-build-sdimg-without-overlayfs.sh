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

wget ${CDN_URL}/friendlydesktop-arm64-images.tgz
tar xzf friendlydesktop-arm64-images.tgz
cp prebuilt/param4sd-plain.txt friendlydesktop-arm64/sd-boot/param4sd.txt
cp prebuilt/partmap-plain.txt friendlydesktop-arm64/sd-boot/partmap.txt
sudo ./mk-sd-image.sh friendlydesktop-arm64

echo "done."
