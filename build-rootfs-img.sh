#!/bin/bash
set -eu

if [ $# -lt 2 ]; then
	echo "Usage: $0 <rootfs dir> <img dir> "
    echo "example:"
    echo "    tar xvzf NETDISK/RK3399/rootfs/rootfs-friendlycore-focal-arm64.tgz"
    echo "    ./build-rootfs-img.sh friendlycore-focal-arm64/rootfs friendlycore-focal-arm64"
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
true ${MKFS:="${TOP}/tools/make_ext4fs"}

if [ ! -d ${ROOTFS_DIR} ]; then
    echo "path '${ROOTFS_DIR}' not found."
    exit 1
fi

MKFS_OPTS="-s -a root -L rootfs"
if echo ${TARGET_OS} | grep friendlywrt -i >/dev/null; then
    # set default uid/gid to 0
    MKFS_OPTS="-0 ${MKFS_OPTS}"
fi

if echo ${TARGET_OS} | grep buildroot -i >/dev/null; then
    # set default uid/gid to 0
    MKFS_OPTS="-0 ${MKFS_OPTS}"
fi

function clean_device_files()
{
	echo "clean device files..."
    (cd ${1}/dev && find . ! -type d -exec rm {} \;)
}
clean_device_files ${ROOTFS_DIR}

if [ ${IMG_SIZE} -eq 0 ]; then
    # calc image size
    ROOTFS_SIZE=`du -s -B 1 ${ROOTFS_DIR} | cut -f1`
    # +1024m + 10% rootfs size
    MAX_IMG_SIZE=$((${ROOTFS_SIZE} + 1024*1024*1024 + ${ROOTFS_SIZE}/5))
    TMPFILE=`tempfile`
    ${MKFS} -s -l ${MAX_IMG_SIZE} -a root -L rootfs /dev/null ${ROOTFS_DIR} > ${TMPFILE}
    IMG_SIZE=`cat ${TMPFILE} | grep "Suggest size:" | cut -f2 -d ':' | awk '{gsub(/^\s+|\s+$/, "");print}'`
    rm -f ${TMPFILE}

    if [ ${ROOTFS_SIZE} -gt ${IMG_SIZE} ]; then
            echo "IMG_SIZE less than ROOTFS_SIZE, why?"
            exit 1
    fi

    # make fs
    ${MKFS} ${MKFS_OPTS} -l ${IMG_SIZE} ${IMG_FILE} ${ROOTFS_DIR}
    if [ $? -ne 0 ]; then
            echo "error: failed to  make rootfs.img."
            exit 1
     fi
else
    ${MKFS} ${MKFS_OPTS} -l ${IMG_SIZE} ${IMG_FILE} ${ROOTFS_DIR}
    if [ $? -ne 0 ]; then
            echo "error: failed to  make rootfs.img."
            exit 1
     fi
fi

if [ ${TARGET_OS} != "eflasher" ]; then
    ${TOP}/tools/generate-partmap-txt.sh ${IMG_SIZE} ${TARGET_OS}
fi
echo "generating ${IMG_FILE} done."
echo 0


