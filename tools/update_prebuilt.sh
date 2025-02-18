#!/bin/bash
set -eu

[ -f ${PWD}/mk-emmc-image.sh ] || {
	echo "Error: please run at the script's home dir"
	exit 1
}

cp -f $2/boot.img $1/
cp -f $2/idbloader.img $1/
cp -f $2/misc.img $1/
cp -f $2/dtbo.img $1/

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

generate_img() {
    local img_name=$1
    echo "Generating empty $img_name"
    local tmpdir=$(mktemp -d)
    local img_blk=$((209715200 / 4096))
    ${MKFS} -E android_sparse -t ext4 -L userdata -M /userdata -b 4096 -d ${tmpdir} $img_name ${img_blk}
    local ret=$?
    rm -rf ${tmpdir}
    return $ret
}

if [ ! -f $1/userdata.img ]; then
    generate_img $1/userdata.img
    RET=$?
    [ $RET -ne 0 ] && exit $RET
fi

if grep -q "(opt:grow)" $1/parameter.txt; then
	if [ ! -f $1/opt.img ]; then
		generate_img $1/opt.img
		RET=$?
		[ $RET -ne 0 ] && exit $RET
	fi
fi

exit 0
