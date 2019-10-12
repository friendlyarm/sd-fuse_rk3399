#!/bin/bash
set -eu

[ -f ${PWD}/mk-emmc-image.sh ] || {
	echo "Error: please run at the script's home dir"
	exit 1
}

true ${SOC:=rk3399}
OUT=${PWD}/out

UBOOT_DIR=$1
KERNEL_DIR=$2
BOOT_DIR=$3
ROOTFS_DIR=$4
PREBUILT=$5

KMODULES_OUTDIR="${OUT}/output_${SOC}_kmodules"


# rootfs
rm -rf ${ROOTFS_DIR}/lib/modules/*
cp -af ${KMODULES_OUTDIR}/* ${ROOTFS_DIR}


exit 0
