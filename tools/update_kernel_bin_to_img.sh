#!/bin/bash
set -eu

[ -f ${PWD}/mk-emmc-image.sh ] || {
	echo "Error: please run at the script's home dir"
	exit 1
}

# Automatically re-run script under sudo if not root
if [ $(id -u) -ne 0 ]; then
        echo "Re-running script under sudo..."
        sudo "$0" "$@"
        exit
fi

TOP=$PWD
true ${MKFS:="${TOP}/tools/make_ext4fs"}
true ${MKFS:="${TOP}/tools/make_ext4fs"}

true ${SOC:=rk3399}
ARCH=arm64
KCFG=nanopi4_linux_defconfig
KIMG=kernel.img
KDTB=resource.img
KALL=nanopi4-images
CROSS_COMPILE=aarch64-linux-gnu-
# ${OUT} ${KERNEL_SRC} ${TOPPATH}/${TARGET_OS} ${TOPPATH}/prebuilt
if [ $# -ne 4 ]; then
        echo "bug: missing arg, $0 needs four args"
        exit
fi
OUT=$1
KERNEL_BUILD_DIR=$2
TARGET_OS=$3
PREBUILT=$4
KMODULES_OUTDIR="${OUT}/output_${SOC}_kmodules"

(cd ${KERNEL_BUILD_DIR} && {
	cp ${KIMG} ${KDTB} ${TOP}/${TARGET_OS}/
})

# copy kernel modules to rootfs.img
if [ -f ${TARGET_OS}/rootfs.img ]; then
    echo "copying kernel module and firmware to rootfs ..."

    # Extract rootfs from img
    simg2img ${TARGET_OS}/rootfs.img ${TARGET_OS}/r.img
    mkdir -p ${OUT}/rootfs_mnt
    mkdir -p ${OUT}/rootfs_new
    mount -t ext4 -o loop ${TARGET_OS}/r.img ${OUT}/rootfs_mnt
    if [ $? -ne 0 ]; then
        echo "failed to mount ${TARGET_OS}/r.img."
        exit 1
    fi
    cp -af ${OUT}/rootfs_mnt/* ${OUT}/rootfs_new/
    umount ${OUT}/rootfs_mnt
    rm -rf ${OUT}/rootfs_mnt
    rm -f ${TARGET_OS}/r.img

    # Processing rootfs_new
    # Here s5pxx18 is different from h3/h5
	
    [ -d ${KMODULES_OUTDIR}/lib/firmware ] && cp -af ${KMODULES_OUTDIR}/lib/firmware/* ${OUT}/rootfs_new/lib/firmware/
    rm -rf ${OUT}/rootfs_new/lib/modules/*
    cp -af ${KMODULES_OUTDIR}/lib/modules/* ${OUT}/rootfs_new/lib/modules/

    MKFS_OPTS="-s -a root -L rootfs"
    if echo ${TARGET_OS} | grep friendlywrt -i >/dev/null; then
        # set default uid/gid to 0
        MKFS_OPTS="-0 ${MKFS_OPTS}"
    fi

    # Make rootfs.img
    ROOTFS_DIR=${OUT}/rootfs_new
    # calc image size
    ROOTFS_SIZE=`du -s -B 1 ${ROOTFS_DIR} | cut -f1`
    # +1024m + 10% rootfs size
    MAX_IMG_SIZE=$((${ROOTFS_SIZE} + 1024*1024*1024 + ${ROOTFS_SIZE}/10))
    TMPFILE=`tempfile`
    ${MKFS} -s -l ${MAX_IMG_SIZE} -a root -L rootfs /dev/null ${ROOTFS_DIR} > ${TMPFILE}
    IMG_SIZE=`cat ${TMPFILE} | grep "Suggest size:" | cut -f2 -d ':' | awk '{gsub(/^\s+|\s+$/, "");print}'`
    rm -f ${TMPFILE}

    if [ ${ROOTFS_SIZE} -gt ${IMG_SIZE} ]; then
            echo "IMG_SIZE less than ROOTFS_SIZE, why?"
            exit 1
    fi

    # make fs
    ${MKFS} ${MKFS_OPTS} -l ${IMG_SIZE} ${TARGET_OS}/rootfs.img ${ROOTFS_DIR}
    if [ $? -ne 0 ]; then
            echo "error: failed to make rootfs.img."
            exit 1
    fi

    if [ ${TARGET_OS} != "eflasher" ]; then
        echo "IMG_SIZE=${IMG_SIZE}" > ${OUT}/${TARGET_OS}_rootfs-img.info
        ${TOP}/tools/generate-partmap-txt.sh ${IMG_SIZE} ${TARGET_OS}
    fi
else 
    echo "not found ${TARGET_OS}/rootfs.img"
    exit 1
fi


