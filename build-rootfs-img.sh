#!/bin/bash

if [ $# -lt 2 ]; then
	echo "Usage: $0 <rootfs dir> <img filename> "
    echo "example:"
    echo "    tar xvzf NETDISK/RK3399/rootfs/rootfs-friendlycore-arm64-20190603.tgz"
    echo "    ./build-rootfs-img.sh friendlycore-arm64/rootfs friendlycore-arm64/rootfs.img"
	exit 0
fi

ROOTFS_DIR=$1
IMG_FILE=$2
IMG_SIZE=$3

TOP=$PWD
true ${MKFS:="${TOP}/tools/make_ext4fs"}

if [ ! -d ${ROOTFS_DIR} ]; then
    echo "path '${ROOTFS_DIR}' not found."
    exit 1
fi

RET=0
if [ -z ${IMG_SIZE} ]; then
    # calc image size
    ROOTFS_SIZE=`du -s -B 1 ${ROOTFS_DIR} | cut -f1`
    MAX_IMG_SIZE=7100000000
    TMPFILE=`tempfile`
    ${MKFS} -s -l ${MAX_IMG_SIZE} -a root -L rootfs /dev/null ${ROOTFS_DIR} > ${TMPFILE}
    IMG_SIZE=`cat ${TMPFILE} | grep "Suggest size:" | cut -f2 -d ':' | awk '{gsub(/^\s+|\s+$/, "");print}'`
    rm -f ${TMPFILE}

    if [ ${ROOTFS_SIZE} -gt ${IMG_SIZE} ]; then
            echo "IMG_SIZE less than ROOTFS_SIZE, why?"
            exit 1
    fi

    # make fs
    ${MKFS} -s -l ${IMG_SIZE} -a root -L rootfs ${IMG_FILE} ${ROOTFS_DIR}
    RET=$?
else
    ${MKFS} -s -l ${IMG_SIZE} -a root -L rootfs ${IMG_FILE} ${ROOTFS_DIR}
    RET=$?
fi

if [ $RET -eq 0 ]; then
    echo "gen ${IMG_FILE} done."
else
    echo "fail to gen ${IMG_FILE}."
fi
exit $RET

