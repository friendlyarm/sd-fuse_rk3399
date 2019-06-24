#!/bin/bash

# Copyright (C) Guangzhou FriendlyARM Computer Tech. Co., Ltd.
# (http://www.friendlyarm.com)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, you can access it online at
# http://www.gnu.org/licenses/gpl-2.0.html.


true ${SOC:=rk3399}
KERNEL_REPO=https://github.com/friendlyarm/kernel-rockchip
KERNEL_BRANCH=nanopi4-linux-v4.4.y

KERNEL_DIRNAME=kernel-$SOC

ARCH=arm64
KCFG=nanopi4_linux_defconfig
KALL=nanopi4-images
KIMG=kernel.img
KDTB=resource.img
CROSS_COMPILER=aarch64-linux-gnu-

# 
# kernel logo:
# 
# convert logo.jpg -type truecolor /tmp/logo.bmp 
# convert logo.jpg -type truecolor /tmp/logo_kernel.bmp
# LOGO=/tmp/logo.bmp
# KERNEL_LOGO=/tmp/logo_kernel.bmp
#

# Automatically re-run script under sudo if not root
if [ $(id -u) -ne 0 ]; then
	echo "Re-running script under sudo..."
	sudo "$0" "$@"
	exit
fi


TOPPATH=$PWD
OUT=$TOPPATH/out
if [ ! -d $OUT ]; then
	echo "path not found: $OUT"
	exit 1
fi
KMODULES_OUTDIR="${OUT}/output_${SOC}_kmodules"

function usage() {
       echo "Usage: $0 <buildroot|friendlycore-arm64|friendlydesktop-arm64|lubuntu|eflasher>"
       echo "# example:"
       echo "# clone kernel source from github:"
       echo "    git clone ${KERNEL_REPO} --depth 1 -b ${KERNEL_BRANCH} ${OUT}/${KERNEL_DIRNAME}"
       echo "# or clone your local repo:"
       echo "    git clone git@192.168.1.2:/path/to/linux.git --depth 1 -b ${KERNEL_BRANCH} out/kernel-${SOC}"
       echo "# then"
       echo "    convert files/logo.jpg -type truecolor /tmp/logo.bmp"
       echo "    convert files/logo.jpg -type truecolor /tmp/logo_kernel.bmp"
       echo "    LOGO=/tmp/logo.bmp KERNEL_LOGO=/tmp/logo_kernel.bmp ./build-kernel.sh eflasher"
       echo "    LOGO=/tmp/logo.bmp KERNEL_LOGO=/tmp/logo_kernel.bmp ./build-kernel.sh friendlycore-arm64"
       echo "    ./mk-emmc-image.sh friendlycore-arm64"
       exit 0
}

if [ -z $1 ]; then
    usage
fi

# ----------------------------------------------------------
# Get target OS
true ${TARGET_OS:=${1,,}}

case ${TARGET_OS} in
buildroot* | android7 | android8 | friendlycore* | friendlydesktop* | lubuntu* | eflasher )
        ;;
*)
        echo "Error: Unsupported target OS: ${TARGET_OS}"
        exit 0
esac

download_img() {
    local RKPARAM=$(dirname $0)/${1}/parameter.txt
    local RKPARAM2=$(dirname $0)/${1}/param4sd.txt
    if [ -f "${RKPARAM}" -o -f "${RKPARAM2}" ]; then
	echo "${1} found."
    else
        cat << EOF
Warn: Image not found for ${1}
----------------
you may download them from the netdisk (dl.friendlyarm.com) to get a higher downloading speed,
the image files are stored in a directory called images-for-eflasher, for example:
    tar xvzf ../NETDISK/images-for-eflasher/friendlycore-arm64-images.tgz
    sudo ./fusing.sh /dev/sdX friendlycore-arm64
----------------
Or, download from http (Y/N)?
EOF
        while read -r -n 1 -t 3600 -s USER_REPLY; do
            if [[ ${USER_REPLY} = [Nn] ]]; then
                echo ${USER_REPLY}
                exit 1
            elif [[ ${USER_REPLY} = [Yy] ]]; then
                echo ${USER_REPLY}
                break;
            fi
        done

        if [ -z ${USER_REPLY} ]; then
            echo "Cancelled."
            exit 1
        fi
        ./tools/get_rom.sh ${1} || exit 1
    fi
}

function build_kernel_modules() {
    rm -rf ${KMODULES_OUTDIR}
    mkdir -p ${KMODULES_OUTDIR}
    make ARCH=${ARCH} INSTALL_MOD_PATH=${KMODULES_OUTDIR} modules -j$(nproc)
    make ARCH=${ARCH} INSTALL_MOD_PATH=${KMODULES_OUTDIR} modules_install
    KREL=`make kernelrelease`
    rm -rf ${KMODULES_OUTDIR}/lib/modules/${KREL}/kernel/drivers/gpu/arm/mali400/
    [ ! -f "${KMODULES_OUTDIR}/lib/modules/${KREL}/modules.dep" ] && depmod -b ${KMODULES_OUTDIR} -E Module.symvers -F System.map -w ${KREL}
    (cd ${KMODULES_OUTDIR} && find . -name \*.ko | xargs ${CROSS_COMPILER}strip --strip-unneeded)
}

download_img ${TARGET_OS}

if [ ! -d ${OUT}/${KERNEL_DIRNAME} ]; then
	git clone ${KERNEL_REPO} --depth 1 -b ${KERNEL_BRANCH} ${OUT}/${KERNEL_DIRNAME}
fi

KERNEL_BUILD_DIR=${OUT}/${KERNEL_DIRNAME}_build
rm -rf ${KERNEL_BUILD_DIR} 
echo "coping kernel src..."
rsync -a --exclude='.git/' ${OUT}/${KERNEL_DIRNAME}/* ${KERNEL_BUILD_DIR}

if [ ! -d /opt/FriendlyARM/toolchain/6.4-aarch64 ]; then
	echo "please install aarch64-gcc-6.4 first, using these commands: "
	echo "\tgit clone https://github.com/friendlyarm/prebuilts.git"
	echo "\tsudo mkdir -p /opt/FriendlyARM/toolchain"
	echo "\tsudo tar xf prebuilts/gcc-x64/aarch64-cortexa53-linux-gnu-6.4.tar.xz -C /opt/FriendlyARM/toolchain/"
	exit 1
fi

if [ -f "${LOGO}" ]; then
	cp -f ${LOGO} ${KERNEL_BUILD_DIR}/logo.bmp
	echo "using ${LOGO} as logo."
else
	echo "using official logo."
fi

if [ -f "${KERNEL_LOGO}" ]; then
        cp -f ${KERNEL_LOGO} ${KERNEL_BUILD_DIR}/logo_kernel.bmp
        echo "using ${KERNEL_LOGO} as kernel logo."
else
        echo "using official kernel logo."
fi

export PATH=/opt/FriendlyARM/toolchain/6.4-aarch64/bin/:$PATH

cd ${KERNEL_BUILD_DIR}
make distclean
touch .scmversion
make ARCH=${ARCH} ${KCFG}
if [ x"${TARGET_OS}" = x"eflasher" ]; then
    cp -avf .config .config.old
    sed -i "s/.*\(PROT_MT_SYNC\).*/CONFIG_TOUCHSCREEN_\1=y/g" .config
    sed -i "s/\(.*PROT_MT_SLOT\).*/# \1 is not set/g" .config
fi

make ARCH=${ARCH} ${KALL} -j$(nproc)
build_kernel_modules

if [ $? -eq 0 ]; then
	cp ${KIMG} ${KDTB} ${TOPPATH}/${TARGET_OS}/
	echo "build kernel ok."
else
	echo "fail to build kernel."
	exit 1
fi

if [ ! -d ${KMODULES_OUTDIR}/lib ]; then
	echo "not found kernel modules."
	exit 1
fi

# update kernel modules
# apt install android-tools-fsutils
cd $TOPPATH
if [ -f ${TARGET_OS}/rootfs.img ]; then
    simg2img ${TARGET_OS}/rootfs.img ${TARGET_OS}/r.img
    mkdir -p ${OUT}/old_rootfs
    mount -t ext4 -o loop ${TARGET_OS}/r.img ${OUT}/old_rootfs
    mkdir -p ${OUT}/rootfs
    rm -rf ${OUT}/rootfs/*
    cp -af ${OUT}/old_rootfs/* ${OUT}/rootfs
    umount ${OUT}/old_rootfs
    rm ${TARGET_OS}/r.img
    rm -rf ${OUT}/old_rootfs

    cp -af ${KMODULES_OUTDIR}/lib/firmware/* ${OUT}/rootfs/lib/firmware/
    rm -rf ${OUT}/rootfs/lib/modules/*
    cp -af ${KMODULES_OUTDIR}/lib/modules/* ${OUT}/rootfs/lib/modules/

    ./build-rootfs-img.sh ${OUT}/rootfs ${TARGET_OS}/rootfs.img
    if [ $? -eq 0 ]; then
        echo "update kernel-modules to rootfs.img ok."
        exit 0
    else
        echo "fail."
        exit 1
    fi
else 
	echo "not found ${TARGET_OS}/rootfs.img"
	exit 1
fi

