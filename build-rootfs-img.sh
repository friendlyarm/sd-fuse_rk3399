#!/bin/bash
set -eu

if [ $# -lt 2 ]; then
	echo "Usage: $0 <rootfs dir> <img dir> "
    echo "example:"
    echo "    tar xvzf NETDISK/RK3399/rootfs/rootfs-friendlycore-lite-focal-arm64.tgz"
    echo "    ./build-rootfs-img.sh friendlycore/rootfs friendlycore-lite-focal-kernel5-arm64"
	exit 0
fi

ROOTFS_DIR=$1
TARGET_OS=$2
IMG_FILE=$TARGET_OS/rootfs.img
if [ $# -eq 3 ]; then
	IMG_SIZE=$3
else
	IMG_SIZE=0
fi

TOP=$PWD
export MKE2FS_CONFIG="${TOP}/tools/mke2fs.conf"
if [ ! -f ${MKE2FS_CONFIG} ]; then
    echo "error: ${MKE2FS_CONFIG} not found."
    exit 1
fi
true ${MKFS:="${TOP}/tools/mke2fs"}

if [ ! -d ${ROOTFS_DIR} ]; then
    echo "path '${ROOTFS_DIR}' not found."
    exit 1
fi

MKFS_OPTS="-E android_sparse -t ext4 -L rootfs -M /root -b 4096"
case ${TARGET_OS} in
friendlywrt* | buildroot*)
    # set default uid/gid to 0
    MKFS_OPTS="-0 ${MKFS_OPTS}"
    ;;
*)
    ;;
esac

# clean device file
(cd ${ROOTFS_DIR}/dev && find . ! -type d -exec rm {} \;)

if [ ${IMG_SIZE} -eq 0 ]; then
    # calc image size
    IMG_SIZE=$(((`du -s -B64M ${ROOTFS_DIR} | cut -f1` + 2) * 1024 * 1024 * 64))
    IMG_BLK=$((${IMG_SIZE} / 4096))
    INODE_SIZE=$((`find ${ROOTFS_DIR} | wc -l` + 128))
    # make fs
    [ -f ${IMG_FILE} ] && rm -f ${IMG_FILE}
    ${MKFS} -N ${INODE_SIZE} ${MKFS_OPTS} -d ${ROOTFS_DIR} ${IMG_FILE} ${IMG_BLK}
else
    IMG_BLK=$((${IMG_SIZE} / 4096))
    INODE_SIZE=$((`find ${ROOTFS_DIR} | wc -l` + 128))
    [ -f ${IMG_FILE} ] && rm -f ${IMG_FILE}
    ${MKFS} -N ${INODE_SIZE} ${MKFS_OPTS} -d ${ROOTFS_DIR} ${IMG_FILE} ${IMG_BLK}
fi

if [ ${TARGET_OS} != "eflasher" ]; then
    ${TOP}/tools/generate-partmap-txt.sh ${IMG_SIZE} ${TARGET_OS}
fi
echo "generating ${IMG_FILE} done."
echo 0


