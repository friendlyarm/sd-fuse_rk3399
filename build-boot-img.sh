#!/bin/bash

if [ $# -lt 2 ]; then
	echo "Usage: $0 <boot dir> <img filename>"
    echo "example:"
    echo "    tar xvzf NETDISK/RK3399/rootfs/rootfs-friendlycore-arm64-20190603.tgz"
    echo "    ./build-boot-img.sh friendlycore-arm64/boot friendlycore-arm64/boot.img"
    exit 1
fi
TOPDIR=$PWD

BOOT_DIR=$1
IMG_FILE=$2

if [ ! -d ${BOOT_DIR} ]; then
    echo "path '${BOOT_DIR}' not found."
    exit 1
fi

# Automatically re-run script under sudo if not root
if [ $(id -u) -ne 0 ]; then
	echo "Re-running script under sudo..."
 	sudo "$0" "$@"
 	exit
fi
# 64M
IMG_SIZE=67108864

TOP=$PWD
true ${MKFS:="${TOP}/tools/make_ext4fs"}

${MKFS} -0 -s -l ${IMG_SIZE} -a root -L boot ${IMG_FILE} ${BOOT_DIR}
RET=$?

if [ $RET -eq 0 ]; then
    echo "generating ${IMG_FILE} done."
else
    echo "failed to generate ${IMG_FILE}."
fi
exit $RET

