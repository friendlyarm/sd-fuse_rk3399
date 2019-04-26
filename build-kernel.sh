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

KERNEL_REPO=https://github.com/friendlyarm/kernel-rockchip
KERNEL_BRANCH=nanopi4-linux-v4.4.y

# 
# kernel logo:
# 
# convert logo.jpg -type truecolor /tmp/logo.bmp 
# convert logo.jpg -type truecolor /tmp/logo_kernel.bmp
# LOGO=/tmp/logo.bmp
# KERNEL_LOGO=/tmp/logo_kernel.bmp
#

declare -a OSNames=("buildroot"
                    "friendlycore-arm64"
                    "friendlydesktop-arm64"
                    "lubuntu"
		    "eflasher")

declare -a RootfsImgSizes=("1604321280"     # buildroot
			"5368709120"       # friendlycore-arm64
			"7000000000"       # friendlydesktop-arm64
			"6000000000"       # lubuntu
			"1604321280")      # eflasher

# Automatically re-run script under sudo if not root
if [ $(id -u) -ne 0 ]; then
	echo "Re-running script under sudo..."
	sudo "$0" "$@"
	exit
fi

function usage() {
       echo "Usage: $0 <buildroot|friendlycore-arm64|friendlydesktop-arm64|lubuntu|eflasher>"
       echo "example:"
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

TOPPATH=$PWD

# ----------------------------------------------------------
# Get platform, target OS

true ${SOC:=rk3399}
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
        echo -n "Warn: Image not found for ${1}, download now (Y/N)? "
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
    OUT="/tmp/output_rk3399_kmodules"
    rm -rf ${OUT}
    mkdir -p ${OUT}
    make ARCH=arm64 INSTALL_MOD_PATH=${OUT} modules -j$(nproc)
    make ARCH=arm64 INSTALL_MOD_PATH=${OUT} modules_install
    KREL=`make kernelrelease`
    rm -rf ${OUT}/lib/modules/${KREL}/kernel/drivers/gpu/arm/mali400/
    [ ! -f "${OUT}/lib/modules/${KREL}/modules.dep" ] && depmod -b ${OUT} -E Module.symvers -F System.map -w ${KREL}
    (cd ${OUT} && find . -name \*.ko | xargs aarch64-linux-gnu-strip --strip-unneeded)
}

download_img ${TARGET_OS}

if [ ! -d kernel-rockchip ]; then
	git clone ${KERNEL_REPO} --depth 1 -b ${KERNEL_BRANCH} kernel-rockchip
fi

KERNELSRC=$TOPPATH/out/kernel-rockchip
mkdir -p $TOPPATH/out
rm -rf ${KERNELSRC} 
echo "coping kernel src..."
cp -af kernel-rockchip ${KERNELSRC}

if [ ! -d /opt/FriendlyARM/toolchain/6.4-aarch64 ]; then
	echo "please install aarch64-gcc-6.4 first, using these commands: "
	echo "\tgit clone https://github.com/friendlyarm/prebuilts.git"
	echo "\tsudo mkdir -p /opt/FriendlyARM/toolchain"
	echo "\tsudo tar xf prebuilts/gcc-x64/aarch64-cortexa53-linux-gnu-6.4.tar.xz -C /opt/FriendlyARM/toolchain/"
	exit 1
fi

if [ -f "${LOGO}" ]; then
	cp -f ${LOGO} ${KERNELSRC}/logo.bmp
	echo "using ${LOGO} as logo."
else
	echo "using official logo."
fi

if [ -f "${KERNEL_LOGO}" ]; then
        cp -f ${KERNEL_LOGO} ${KERNELSRC}/logo_kernel.bmp
        echo "using ${KERNEL_LOGO} as kernel logo."
else
        echo "using official kernel logo."
fi

cd ${KERNELSRC}
make distclean
make ARCH=arm64 nanopi4_linux_defconfig
if [ x"${TARGET_OS}" = x"eflasher" ]; then
    cp -avf .config .config.old
    sed -i "s/.*\(PROT_MT_SYNC\).*/CONFIG_TOUCHSCREEN_\1=y/g" .config
    sed -i "s/\(.*PROT_MT_SLOT\).*/# \1 is not set/g" .config
fi
export PATH=/opt/FriendlyARM/toolchain/6.4-aarch64/bin/:$PATH
make ARCH=arm64 nanopi4-images -j$(nproc)
build_kernel_modules

if [ $? -eq 0 ]; then
	cp kernel.img resource.img ${TOPPATH}/${TARGET_OS}/
	echo "build kernel ok."
else
	echo "fail to build kernel."
	exit 1
fi

if [ ! -d /tmp/output_rk3399_kmodules/lib ]; then
	echo "not found kernel modules."
	exit 1
fi

# update kernel modules
# apt install android-tools-fsutils
cd $TOPPATH
if [ -f ${TARGET_OS}/rootfs.img ]; then
    simg2img ${TARGET_OS}/rootfs.img ${TARGET_OS}/r.img
    mkdir -p /mnt/rootfs
    mount -t ext4 -o loop ${TARGET_OS}/r.img /mnt/rootfs
    mkdir -p rootfs
    rm -rf rootfs/*
    cp -af /mnt/rootfs/* rootfs
    umount /mnt/rootfs
    rm ${TARGET_OS}/r.img

    cp -af /tmp/output_rk3399_kmodules/lib/firmware/* rootfs/lib/firmware/
    rm -rf rootfs/lib/modules/*
    cp -af /tmp/output_rk3399_kmodules/lib/modules/* rootfs/lib/modules/

    Index=0
    FOUND=0
    for (( i=0; i<${#OSNames[@]}; i++ ));
    do
        if [ "x${OSNames[$i]}" = "x${TARGET_OS}" ]; then
                Index=$i
                FOUND=1
                break
        fi
    done
    if [ ${FOUND} == 0 ]; then
        echo "unknow: ${TARGET_OS}"
	exit 1
    fi

    ./tools/make_ext4fs -s -l ${RootfsImgSizes[$Index]} -a root -L rootfs rootfs.img rootfs
    cp rootfs.img ${TARGET_OS}/

    echo "update kernel-modules to rootfs.img ok."
    exit 0
else 
	echo "not found ${TARGET_OS}/rootfs.img"
	exit 1
fi

