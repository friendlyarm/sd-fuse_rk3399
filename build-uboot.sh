#!/bin/bash
set -eu

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
true ${DISABLE_MKIMG:=0}

UBOOT_REPO=https://github.com/friendlyarm/uboot-rockchip
UBOOT_BRANCH=nanopi4-v2017.09

TOPPATH=$PWD
OUT=$TOPPATH/out
if [ ! -d $OUT ]; then
	echo "path not found: $OUT"
	exit 1
fi

true ${UBOOT_SRC:=${OUT}/uboot-${SOC}}
echo "uboot src: ${UBOOT_SRC}"

# You need to install:
# apt-get install swig python-dev python3-dev

function usage() {
       echo "Usage: $0 <debian|buildroot|friendlycore-arm64|friendlydesktop-arm64|lubuntu|friendlywrt|eflasher|android10>"
       echo "# example:"
       echo "# clone uboot source from github:"
       echo "    git clone ${UBOOT_REPO} --depth 1 -b ${UBOOT_BRANCH} ${UBOOT_SRC}"
       echo "# or clone your local repo:"
       echo "    git clone git@192.168.1.2:/path/to/uboot.git --depth 1 -b ${UBOOT_BRANCH} ${UBOOT_SRC}"
       echo "# then"
       echo "    ./build-uboot.sh friendlycore "
       echo "    ./mk-emmc-image.sh friendlycore "
       echo "# also can do:"
       echo "	UBOOT_SRC=~/myuboot ./build-uboot.sh friendlycore"
       exit 0
}

if [ $# -ne 1 ]; then
    usage
fi

# ----------------------------------------------------------
# Get target OS
true ${TARGET_OS:=${1,,}}

case ${TARGET_OS} in
debian* | buildroot* | android7 | android8 | android10 | friendlycore* | friendlydesktop* | lubuntu* | friendlywrt | eflasher )
        ;;
*)
        echo "Error: Unsupported target OS: ${TARGET_OS}"
        exit 0
esac

# Automatically re-run script under sudo if not root
# if [ $(id -u) -ne 0 ]; then
# 	echo "Re-running script under sudo..."
# 	sudo UBOOT_SRC=${UBOOT_SRC} DISABLE_MKIMG=${DISABLE_MKIMG} "$0" "$@"
# 	exit
# fi

download_img() {
    local RKPARAM=$(dirname $0)/${1}/parameter.txt
    case ${1} in
    eflasher)
        RKPARAM=$(dirname $0)/${1}/partmap.txt
        ;;
    esac

    if [ -f "${RKPARAM}" ]; then
        echo ""
    else
	ROMFILE=`./tools/get_pkg_filename.sh ${1}`
        cat << EOF
Warn: Image not found for "${1}"
----------------
you may download them from the netdisk (dl.friendlyarm.com) to get a higher downloading speed,
the image files are stored in a directory called images-for-eflasher, for example:
    tar xvzf /path/to/NETDISK/images-for-eflasher/${ROMFILE}
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
        ./tools/get_rom.sh "${1}" || exit 1
    fi
}

if [ ! -d ${UBOOT_SRC} ]; then
	git clone ${UBOOT_REPO} --depth 1 -b ${UBOOT_BRANCH} ${UBOOT_SRC}
fi
if [ ! -d ${UBOOT_SRC}/../rkbin ]; then
    (cd ${UBOOT_SRC}/../ && {
        git clone https://github.com/friendlyarm/rkbin
        cd rkbin
        git reset 25de1a8bffb1e971f1a69d1aa4bc4f9e3d352ea3 --hard
    })
fi

if [ ! -d /opt/FriendlyARM/toolchain/6.4-aarch64 ]; then
	echo "please install aarch64-gcc-6.4 first, using these commands: "
	echo "\tgit clone https://github.com/friendlyarm/prebuilts.git -b master --depth 1"
	echo "\tcd prebuilts/gcc-x64"
	echo "\tcat toolchain-6.4-aarch64.tar.gz* | sudo tar xz -C /"
	exit 1
fi

export PATH=/opt/FriendlyARM/toolchain/6.4-aarch64/bin/:$PATH

if ! [ -x "$(command -v simg2img)" ]; then
    sudo apt install android-tools-fsutils
fi

if ! [ -x "$(command -v swig)" ]; then
    sudo apt install swig
fi

# get include path for this python version
INCLUDE_PY=$(python -c "from distutils import sysconfig as s; print s.get_config_vars()['INCLUDEPY']")
if [ ! -f "${INCLUDE_PY}/Python.h" ]; then
    sudo apt install python-dev python3-dev
fi  

cd ${UBOOT_SRC}
make distclean
./make.sh nanopi4

if [ $? -ne 0 ]; then
	echo "failed to build uboot."
	exit 1
fi

if [ x"$DISABLE_MKIMG" = x"1" ]; then
    exit 0
fi

echo "building uboot ok."
cd ${TOPPATH}
download_img ${TARGET_OS}
./tools/update_uboot_bin.sh ${UBOOT_SRC} ${TOPPATH}/${TARGET_OS}
if [ $? -eq 0 ]; then
    echo "updating ${TARGET_OS}/bootloader.img ok."
else
    echo "failed."
    exit 1
fi

exit 0
