#!/bin/bash
set -eu

# Copyright (C) Guangzhou FriendlyElec Computer Tech. Co., Ltd.
# (http://www.friendlyelec.com)
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
true ${DISABLE_MKIMG:=0}
true ${DISABLE_BUILDKERNEL:=0}
true ${LOGO:=}
true ${KERNEL_LOGO:=}
true ${MK_HEADERS_DEB:=0}
true ${BUILD_THIRD_PARTY_DRIVER:=1}
true ${KCFG:=nanopi4_linux_defconfig}

KERNEL_REPO=https://github.com/friendlyarm/kernel-rockchip
KERNEL_BRANCH=nanopi4-v4.19.y
ARCH=arm64
KALL=nanopi4-images
CROSS_COMPILE=aarch64-linux-gnu-
export PATH=/opt/FriendlyARM/toolchain/6.4-aarch64/bin/:$PATH

declare -a KERNEL_3RD_DRIVERS=("https://github.com/friendlyarm/rtl8821CU" "https://github.com/friendlyarm/rtl8822bu" "https://github.com/friendlyarm/rtl8812au")
declare -a KERNEL_3RD_DRIVER_BRANCHES=("nanopi-r2" "nanopi-r2" "nanopi-r2")
declare -a KERNEL_3RD_DRIVER_NAME=("rtl8821CU" "rtl8822bu" "rtl8812au")
build_external_module() {
    DRIVER_REPO=$1
    DRIVER_BRANCHE=$2
    DRIVER_NAME=$3

    (cd ${OUT} && {
        if [ ! -d ${DRIVER_NAME} ]; then
            git clone ${DRIVER_REPO} -b ${DRIVER_BRANCHE} ${DRIVER_NAME}
        else
            (cd ${DRIVER_NAME} && {
                make CROSS_COMPILE=${CROSS_COMPILE} ARCH=${ARCH} KSRC=${KERNEL_SRC} CONFIG_VENDOR_FRIENDLYARM=y clean
            })
        fi
        (cd ${DRIVER_NAME} && {
            make CROSS_COMPILE=${CROSS_COMPILE} ARCH=${ARCH} KSRC=${KERNEL_SRC} CONFIG_VENDOR_FRIENDLYARM=y -j$(nproc)
            if [ $? -ne 0 ]; then
                echo "failed to build 3rd kernel modules: ${DRIVER_NAME}"
                exit 1
            fi
            ${CROSS_COMPILE}strip --strip-unneeded ${DRIVER_NAME}.ko
            cp ${DRIVER_NAME}.ko ${KMODULES_OUTDIR}/lib/modules/${KERNEL_VER} -afv
        })
    })
}

# 
# kernel logo:
# 
# convert logo.jpg -type truecolor /tmp/logo.bmp 
# convert logo.jpg -type truecolor /tmp/logo_kernel.bmp
# LOGO=/tmp/logo.bmp
# KERNEL_LOGO=/tmp/logo_kernel.bmp
#

TOPPATH=$PWD
OUT=$TOPPATH/out
if [ ! -d $OUT ]; then
	echo "path not found: $OUT"
	exit 1
fi
KMODULES_OUTDIR="${OUT}/output_${SOC}_kmodules"
true ${KERNEL_SRC:=${OUT}/kernel-${SOC}}

function usage() {
       echo "Usage: $0 <android10|android11|buildroot|friendlycore-focal-arm64|debian-buster-desktop-arm64|debian-bullseye-desktop-arm64|friendlycore-lite-focal-kernel4-arm64|friendlywrt-kernel4>"
       echo "# example:"
       echo "# clone kernel source from github:"
       echo "    git clone ${KERNEL_REPO} --depth 1 -b ${KERNEL_BRANCH} ${KERNEL_SRC}"
       echo "# or clone your local repo:"
       echo "    git clone git@192.168.1.2:/path/to/linux.git --depth 1 -b ${KERNEL_BRANCH} ${KERNEL_SRC}"
       echo "# then"
       echo "    convert files/logo.jpg -type truecolor /tmp/logo.bmp"
       echo "    convert files/logo.jpg -type truecolor /tmp/logo_kernel.bmp"
       echo "    LOGO=/tmp/logo.bmp KERNEL_LOGO=/tmp/logo_kernel.bmp ./build-kernel.sh eflasher"
       echo "    LOGO=/tmp/logo.bmp KERNEL_LOGO=/tmp/logo_kernel.bmp ./build-kernel.sh debian-buster-desktop-arm64"
       echo "    ./mk-emmc-image.sh debian-buster-desktop-arm64"
       echo "# also can do:"
       echo "    KERNEL_SRC=~/mykernel ./build-kernel.sh debian-buster-desktop-arm64"
       echo "# other options, build kernel-headers, enable/disable 3rd drivers:"
       echo "    MK_HEADERS_DEB=1 BUILD_THIRD_PARTY_DRIVER=0 ./build-kernel.sh debian-buster-desktop-arm64"
       exit 0
}

if [ $# -ne 1 ]; then
    usage
fi

# ----------------------------------------------------------
# Get target OS
true ${TARGET_OS:=${1,,}}


case ${TARGET_OS} in
buildroot*|debian-buster-desktop-arm64|debian-bullseye-desktop-arm64|android10|android11|friendlycore-lite-focal-kernel4-arm64|friendlycore-focal-arm64|friendlywrt* )
        ;;
*)
        echo "Error: Unsupported target OS: ${TARGET_OS}"
        exit 1
esac

download_img() {
    local RKPARAM=$(dirname $0)/${1}/parameter.txt
    case ${1} in
    eflasher)
        RKPARAM=$(dirname $0)/${1}/partmap.txt
        ;;
    esac
    if [ -f "${RKPARAM}" ]; then
	    echo "${1} found."
    else
	ROMFILE=`./tools/get_pkg_filename.sh ${1}`
        cat << EOF
Warn: Image not found for ${1}
----------------
you may download it from the netdisk (dl.friendlyarm.com) to get a higher downloading speed,
the image files are stored in a directory called "03_Partition image files", for example:
    tar xvzf /path/to/NetDrive/03_Partition\ image\ files/${ROMFILE}
----------------
Do you want to download it now via http? (Y/N):
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

if [ ! -d ${KERNEL_SRC} ]; then
	git clone ${KERNEL_REPO} --depth 1 -b ${KERNEL_BRANCH} ${KERNEL_SRC}
fi

if [ ! -d /opt/FriendlyARM/toolchain/6.4-aarch64 ]; then
	echo "please install aarch64-gcc-6.4 first, using these commands: "
	echo "\tgit clone https://github.com/friendlyarm/prebuilts.git -b master --depth 1"
	echo "\tcd prebuilts/gcc-x64"
	echo "\tcat toolchain-6.4-aarch64.tar.gz* | sudo tar xz -C /"
	exit 1
fi

if [ -f "${LOGO}" ]; then
	cp -f ${LOGO} ${KERNEL_SRC}/logo.bmp
	echo "using ${LOGO} as logo."
else
	echo "using official logo."
fi

if [ -f "${KERNEL_LOGO}" ]; then
        cp -f ${KERNEL_LOGO} ${KERNEL_SRC}/logo_kernel.bmp
        echo "using ${KERNEL_LOGO} as kernel logo."
else
        echo "using official kernel logo."
fi

function build_kernel() {
    cd ${KERNEL_SRC}
    make distclean
    touch .scmversion
    make CROSS_COMPILE=${CROSS_COMPILE} ARCH=${ARCH} ${KCFG}
    if [ $? -ne 0 ]; then
        echo "failed to build kernel."
        exit 1
    fi
    if [ x"${TARGET_OS}" = x"eflasher" ]; then
        cp -avf .config .config.old
        sed -i "s/.*\(PROT_MT_SYNC\).*/CONFIG_TOUCHSCREEN_\1=y/g" .config
        sed -i "s/\(.*PROT_MT_SLOT\).*/# \1 is not set/g" .config
    fi

    make CROSS_COMPILE=${CROSS_COMPILE} ARCH=${ARCH} ${KALL} -j$(nproc)
    if [ $? -ne 0 ]; then
            echo "failed to build kernel."
            exit 1
    fi

    rm -rf ${KMODULES_OUTDIR}
    mkdir -p ${KMODULES_OUTDIR}
    make CROSS_COMPILE=${CROSS_COMPILE} ARCH=${ARCH} INSTALL_MOD_PATH=${KMODULES_OUTDIR} modules -j$(nproc)
    if [ $? -ne 0 ]; then
        echo "failed to build kernel modules."
            exit 1
    fi
    make CROSS_COMPILE=${CROSS_COMPILE} ARCH=${ARCH} INSTALL_MOD_PATH=${KMODULES_OUTDIR} modules_install
    if [ $? -ne 0 ]; then
        echo "failed to build kernel modules."
            exit 1
    fi
    KERNEL_VER=`make CROSS_COMPILE=${CROSS_COMPILE} ARCH=${ARCH} kernelrelease`
	rm -rf ${KMODULES_OUTDIR}/lib/modules/${KERNEL_VER}/kernel/drivers/gpu/arm/mali400/
	[ ! -f "${KMODULES_OUTDIR}/lib/modules/${KERNEL_VER}/modules.dep" ] && depmod -b ${KMODULES_OUTDIR} -E Module.symvers -F System.map -w ${KERNEL_VER}
	(cd ${KMODULES_OUTDIR} && find . -name \*.ko | xargs ${CROSS_COMPILE}strip --strip-unneeded)

    # build cryptodev-linux
    (cd ${OUT} && {
        if [ ! -d cryptodev-linux ]; then
            git clone https://github.com/cryptodev-linux/cryptodev-linux.git -b master cryptodev-linux
        fi
        (cd cryptodev-linux && {
            make CROSS_COMPILE=${CROSS_COMPILE} ARCH=${ARCH} KERNEL_DIR=${KERNEL_SRC}
            cp cryptodev.ko ${KMODULES_OUTDIR}/lib/modules/${KERNEL_VER} -afv
        })
    })

    # build usb wifi driver
    if [ ${BUILD_THIRD_PARTY_DRIVER} -eq 1 ]; then
        for (( i=0; i<${#KERNEL_3RD_DRIVERS[@]}; i++ ));
        do
            build_external_module ${KERNEL_3RD_DRIVERS[$i]} ${KERNEL_3RD_DRIVER_BRANCHES[$i]} ${KERNEL_3RD_DRIVER_NAME[$i]}
        done
    fi

    if [ ! -d ${KMODULES_OUTDIR}/lib ]; then
        echo "not found kernel modules."
        exit 1
    fi

    (cd ${KMODULES_OUTDIR}/lib/modules/${KERNEL_VER}/ && {
        rm -rf ./build ./source
    	echo "depmod ${KMODULES_OUTDIR} ${KERNEL_VER} ..."
        depmod -a -b ${KMODULES_OUTDIR} ${KERNEL_VER}
    })

    if [ ${MK_HEADERS_DEB} -eq 1 ]; then
        KERNEL_HEADERS_DEB=${OUT}/linux-headers-${KERNEL_VER}.deb
        rm -f ${KERNEL_HEADERS_DEB}
        make CROSS_COMPILE=${CROSS_COMPILE} ARCH=${ARCH} bindeb-pkg
        if [ $? -ne 0 ]; then
            echo "failed to build kernel header."
            exit 1
        fi

	    (cd ${KERNEL_SRC}/debian/hdrtmp && {
	        find usr/src/linux-headers*/scripts/ \
	            -name "*.o" -o -name ".*.cmd" | xargs rm -rf

	        HEADERS_SCRIPT_DIR=${TOPPATH}/files/linux-headers-4.19.y-bin_arm64/scripts
	        if [ -d ${HEADERS_SCRIPT_DIR} ]; then
	            cp -avf ${HEADERS_SCRIPT_DIR}/* ./usr/src/linux-headers-*${KERNEL_VER}*/scripts/
	            if [ $? -ne 0 ]; then
	                echo "failed to copy bin file to /usr/src/linux-headers-${KERNEL_VER}."
	                exit 1
	            fi
	        else
	            echo "not found files/linux-headers-x.y.z-bin_arm64, why?"
	            exit 1
	        fi

	        find . -type f ! -path './DEBIAN/*' -printf '%P\0' | xargs -r0 md5sum > DEBIAN/md5sums
	    })
	    dpkg -b ${KERNEL_SRC}/debian/hdrtmp ${KERNEL_HEADERS_DEB}
	    if [ $? -ne 0 ]; then
	        echo "failed to re-make deb package."
	        exit 1
	    fi

	    # clean up
	    (cd $TOPPATH && {
	        rm -f linux-*${KERNEL_VER}*_arm64.buildinfo
	        rm -f linux-*${KERNEL_VER}*_arm64.changes
	        rm -f linux-headers-*${KERNEL_VER}*_arm64.deb
	        rm -f linux-image-*${KERNEL_VER}*_arm64.deb
	        rm -f linux-libc-dev_*${KERNEL_VER}*_arm64.deb
			rm -f linux-firmware-image-*${KERNEL_VER}*_arm64.deb
	    })
	fi
    echo "building kernel ok."
}

if [ $DISABLE_BUILDKERNEL -eq 0 ]; then
    build_kernel
fi

if [ $DISABLE_MKIMG -eq 1 ]; then
    exit 0
fi
if ! [ -x "$(command -v simg2img)" ]; then
    sudo apt update
    sudo apt install android-tools-fsutils
fi

cd ${TOPPATH}
download_img ${TARGET_OS}
./tools/update_kernel_bin_to_img.sh ${OUT} ${KERNEL_SRC} ${TARGET_OS} ${TOPPATH}/prebuilt

if [ $? -eq 0 ]; then
    echo "updating kernel ok."
else
    echo "failed."
    exit 1
fi

if [ ${MK_HEADERS_DEB} -eq 1 ]; then
    echo "-----------------------------------------"
    echo "the kernel header package has been generated:"
    echo "    ${KERNEL_HEADERS_DEB}"
    echo "-----------------------------------------"
fi
