#!/bin/bash

if [ $# -lt 2 ]; then
	echo "Usage: $0 <dir> <img filename> <img dir>"
    echo "example:"
    echo "    ./tools/make-img.sh <dir> opt.img friendlywrt24-docker"
    exit 1
fi
TOP=$PWD

SRC_DIR=$1
IMG_FILE=$2
TARGET_OS=$3
true ${IMG_SIZE:=0}

if [ ! -d ${SRC_DIR} ]; then
    echo "error: path ${SRC_DIR} not found."
    exit 1
fi

# ----------------------------------------------------------
# Get host machine arch
HOST_ARCH=
if uname -mpi | grep aarch64 >/dev/null; then
    HOST_ARCH="aarch64/"
fi

# Automatically re-run script under sudo if not root
if [ $(id -u) -ne 0 ]; then
    echo "Re-running script under sudo..."
    sudo --preserve-env "$0" "$@"
    exit
fi

TEMPFILE=$(mktemp /tmp/mke2fs.XXXXXX)
>/tmp/make-img-sh-result

make_ext4_img() {
    local RET=0
    local MKFS_PID=
    local MKFS="${TOP}/tools/${HOST_ARCH}mke2fs"
    local MKFS_OPTS="-E android_sparse -t ext4 -L rootfs -M /root -b 4096"

    case ${TARGET_OS} in
    friendlywrt* | buildroot*)
        # set default uid/gid to 0
        MKFS_OPTS="-0 ${MKFS_OPTS}"
        ;;
    *)
        ;;
    esac

    if [ ${IMG_SIZE} -le 0 ]; then
        # calc image size
        IMG_SIZE=$(((`du -s -B64M ${SRC_DIR} | cut -f1` + 3) * 1024 * 1024 * 64))
        IMG_BLK=$((${IMG_SIZE} / 4096))
        INODE_SIZE=$((`find ${SRC_DIR} | wc -l` + 128))
        # make fs
        [ -f ${TARGET_OS}/${IMG_FILE} ] && rm -f ${TARGET_OS}/${IMG_FILE}
        set +e
        MKE2FS_CONFIG="${TOP}/tools/mke2fs.conf" ${MKFS} -N ${INODE_SIZE} ${MKFS_OPTS} -d ${SRC_DIR} ${TARGET_OS}/${IMG_FILE} ${IMG_BLK} | tee ${TEMPFILE} &
        MKFS_PID=$!
        wait $MKFS_PID
        RET=$?
        set -e
    else
        IMG_BLK=$((${IMG_SIZE} / 4096))
        INODE_SIZE=$((`find ${SRC_DIR} | wc -l` + 128))
        [ -f ${TARGET_OS}/${IMG_FILE} ] && rm -f ${TARGET_OS}/${IMG_FILE}
        set +e
        MKE2FS_CONFIG="${TOP}/tools/mke2fs.conf" ${MKFS} -N ${INODE_SIZE} ${MKFS_OPTS} -d ${SRC_DIR} ${TARGET_OS}/${IMG_FILE} ${IMG_BLK} | tee ${TEMPFILE} &
        MKFS_PID=$!
        wait $MKFS_PID
        RET=$?
        set -e
    fi
    if [ $RET -ne 0 ]; then
        oom_log=$(dmesg | tail -n 50 | grep -i 'killed process')
        if echo "$oom_log" | grep -q "Killed process ${MKFS_PID}"; then
            echo "Error: failed to generate ${TARGET_OS}/${IMG_FILE}, mke2fs was killed by oom-killer, please ensure that there is sufficient system memory to execute this program."
        else
            echo "Error: failed to generate ${TARGET_OS}/${IMG_FILE}, mke2fs failed with exit code ${RET}"
        fi
        exit $RET
    fi
}

make_ext4_img
if [ -f ${TEMPFILE} ]; then
    OUTPUT=$(cat ${TEMPFILE})
    UUID=$(echo "$OUTPUT" | grep -oP 'Filesystem UUID: \K\S+')
    echo "UUID=${UUID}" > /tmp/make-img-sh-result
    echo "generating ${TARGET_OS}/${IMG_FILE} done."
    rm -f ${TEMPFILE}
    exit 0
else
    echo "not found ${TEMPFILE}, why?"
    exit 1
fi

