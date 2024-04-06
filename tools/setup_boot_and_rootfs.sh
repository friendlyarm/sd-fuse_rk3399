#!/bin/bash
set -eu

[ -f ${PWD}/mk-emmc-image.sh ] || {
	echo "Error: please run at the script's home dir"
	exit 1
}

TOP=$PWD
true ${SOC:=rk3399}
KIMG=kernel.img
KDTB=resource.img
OUT=${PWD}/out

UBOOT_DIR=$1
KERNEL_DIR=$2
BOOT_DIR=$3
ROOTFS_DIR=$4
PREBUILT=$5
TARGET_OS=$(echo ${6,,}|sed 's/\///g')

HOST_ARCH=
if uname -mpi | grep aarch64 >/dev/null; then
    HOST_ARCH="aarch64/"
fi

# kernel bin
KMODULES_OUTDIR="${OUT}/output_${SOC}_kmodules"
(cd ${KERNEL_DIR} && {
    # gen kernel.img
    ${TOP}/tools/${HOST_ARCH}mkkrnlimg arch/arm64/boot/Image ${KIMG}
	
	mkdir -p ${OUT}/kernel-dtbs
	rm -rf ${OUT}/kernel-dtbs/*

	cp -f arch/arm64/boot/dts/rockchip/rk3399-nanopi-m4.dtb ${OUT}/kernel-dtbs/rk3399-nanopi4-rev01.dtb
	cp -f arch/arm64/boot/dts/rockchip/rk3399-nanopi-m4-v2.dtb ${OUT}/kernel-dtbs/rk3399-nanopi4-rev21.dtb
	cp -f arch/arm64/boot/dts/rockchip/rk3399-nanopi-m4b.dtb ${OUT}/kernel-dtbs/rk3399-nanopi4-rev22.dtb
	cp -f arch/arm64/boot/dts/rockchip/rk3399-nanopi-neo4.dtb ${OUT}/kernel-dtbs/rk3399-nanopi4-rev04.dtb
	cp -f arch/arm64/boot/dts/rockchip/rk3399-nanopi-som.dtb ${OUT}/kernel-dtbs/rk3399-nanopi4-rev06.dtb
	cp -f arch/arm64/boot/dts/rockchip/rk3399-nanopi-som-v2.dtb ${OUT}/kernel-dtbs/rk3399-nanopi4-rev07.dtb
	cp -f arch/arm64/boot/dts/rockchip/rk3399-nanopi-r4s.dtb ${OUT}/kernel-dtbs/rk3399-nanopi4-rev09.dtb
	cp -f arch/arm64/boot/dts/rockchip/rk3399-nanopi-r4s.dtb ${OUT}/kernel-dtbs/rk3399-nanopi4-rev0a.dtb
	cp -f arch/arm64/boot/dts/rockchip/rk3399-nanopi-r4se.dtb ${OUT}/kernel-dtbs/rk3399-nanopi4-rev0b.dtb
	cp -f arch/arm64/boot/dts/rockchip/rk3399-nanopc-t4.dtb ${OUT}/kernel-dtbs/rk3399-nanopi4-rev00.dtb

    # gen resource.img
    ${TOP}/tools/${HOST_ARCH}resource_tool --dtbname ${OUT}/kernel-dtbs/*.dtb \
            ${TOP}/prebuilt/boot/logo.bmp ${TOP}/prebuilt/boot/logo_kernel.bmp

    cp ${KIMG} ${KDTB} ${TOP}/${TARGET_OS}/
})

# rootfs
rm -rf ${ROOTFS_DIR}/lib/modules/*
(cd ${KMODULES_OUTDIR}/lib/ && {
        tar -cf - * | tar -xf - -p --same-owner --numeric-owner -C `readlink -f ${ROOTFS_DIR}/lib`
})

# firmware
if [ ! -d ${ROOTFS_DIR}/system/etc/firmware ]; then
	tar xzf ${PREBUILT}/firmware/system.tgz -C ${ROOTFS_DIR}/
	(cd  ${ROOTFS_DIR}/etc/ && {
		if [ ! -e firmware ]; then
			ln -s /system/etc/firmware .
		fi
	})
fi

if [ ! -d ${ROOTFS_DIR}/lib/firmware/rockchip ]; then
	tar xzf ${PREBUILT}/firmware/lib.tgz -C ${ROOTFS_DIR}/
fi

exit 0
