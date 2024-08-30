#!/bin/bash

if [ $# -lt 2 ]; then
	echo "Usage: $0 <boot dir> <img filename>"
    echo "example:"
    echo "    tar xvzf NETDISK/RK3399/rootfs/rootfs-ubuntu-noble-core-arm64-20190603.tgz"
    echo "    ./build-boot-img.sh ubuntu-noble-core-arm64/boot ubuntu-noble-core-arm64/boot.img"
    exit 1
fi
TOPPATH=$PWD

BOOT_DIR=$1
IMG_FILE=$2

if [ ! -d ${BOOT_DIR} ]; then
    echo "error: path ${BOOT_DIR} not found."
    exit 1
fi

. ${TOPPATH}/tools/util.sh
check_and_install_package

# 64M
IMG_SIZE=67108864

TOP=$PWD
HOST_ARCH=
if uname -mpi | grep aarch64 >/dev/null; then
    HOST_ARCH="aarch64/"
fi
export MKE2FS_CONFIG="${TOP}/tools/mke2fs.conf"
if [ ! -f ${MKE2FS_CONFIG} ]; then
    echo "error: ${MKE2FS_CONFIG} not found."
    exit 1
fi
true ${MKFS:="${TOP}/tools/${HOST_ARCH}mke2fs"}
IMG_BLK=$((${IMG_SIZE} / 4096))
INODE_SIZE=$((`find ${BOOT_DIR} | wc -l` + 128))
${MKFS} -N ${INODE_SIZE} -0 -E android_sparse -t ext4 -L boot -M /root -b 4096 -d ${BOOT_DIR} ${IMG_FILE} ${IMG_BLK}
RET=$?

if [ $RET -eq 0 ]; then
    echo "generating ${IMG_FILE} done."
else
    echo "failed to generate ${IMG_FILE}."
fi
exit $RET
