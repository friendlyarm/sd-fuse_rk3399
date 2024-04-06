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
# ----------------------------------------------------------
# Checking device for fusing

if [ $# -lt 2 ]; then
	echo "Usage: $0 <DEVICE|RAWFILE> <OS>"
	exit 0
fi

if [ ! -e $1 ]; then
	echo "Error: $1 does not exist."
	exit 1
fi

if [ ! -d $2 ]; then
    echo "Error: $2 does not exist."
    exit 1
fi

true ${RK_PARAMETER_TXT:=}
if [ -z $RK_PARAMETER_TXT ]; then
	if [ -f $2/parameter.txt ]; then
		RK_PARAMETER_TXT=$(dirname $0)/${2}/parameter.txt
	fi
fi
if [ -z $RK_PARAMETER_TXT ]; then
		echo "Error: pls set RK_PARAMETER_TXT."
		exit 1
fi

case $1 in
/dev/sd[a-z] | /dev/loop[0-9]* | /dev/mmcblk[0-9]*)
	DEV_NAME=`basename $1`
	BLOCK_CNT=`cat /sys/block/${DEV_NAME}/size`
   ;;
*)
	echo "Error: Unsupported SD reader ($1)"
	exit 0
esac

case $1 in
/dev/sd[a-z])
		REMOVABLE=`cat /sys/block/${DEV_NAME}/removable` ;;
/dev/mmcblk[0-9]* | /dev/loop[0-9]*)
		REMOVABLE=1 ;;
*)
	echo "Error: Unsupported SD reader"
	exit 0
esac

if [ ${REMOVABLE} -le 0 ]; then
	echo "Error: $1 is a non-removable device. Stop."
	exit 1
fi

if [ -z ${BLOCK_CNT} -o ${BLOCK_CNT} -le 0 ]; then
	echo "Error: $1 is inaccessible. Stop fusing now!"
	exit 1
fi

let DEV_SIZE=${BLOCK_CNT}/2
if [ ${DEV_SIZE} -gt 64000000 ]; then
	echo "Error: $1 size (${DEV_SIZE} KB) is too large"
	exit 1
fi

true ${MIN_SIZE:=600000}
if [ ${DEV_SIZE} -le ${MIN_SIZE} ]; then
    echo "Error: $1 size (${DEV_SIZE} KB) is too small"
    echo "       please try another SD card."
    exit 1
fi

# Automatically re-run script under sudo if not root
if [ -b $1 -a $(id -u) -ne 0 ]; then
	echo "Re-running script under sudo..."
	sudo --preserve-env "$0" "$@"
	exit
fi

HOST_ARCH=
if uname -mpi | grep aarch64 >/dev/null; then
    HOST_ARCH="aarch64/"
fi

# ----------------------------------------------------------
# Fusing idbloader, bootloader, trust to card
true ${BOOT_DIR:=./prebuilt}

function fusing_bin() {
	[ -z $2 -o ! -f $1 ] && return 1

	echo "---------------------------------"
	echo "$1 fusing"
	echo "dd if=$1 of=/dev/${DEV_NAME} bs=512 seek=$2"
	dd if=$1 of=/dev/${DEV_NAME} bs=512 seek=$2 conv=fdatasync
	ddret=$?
}

# umount all at first
if [ ! -z ${DEV_NAME} ]; then
	set +e
	umount /dev/${DEV_NAME}* > /dev/null 2>&1
	set -e
fi

#<Message Display>
echo "---------------------------------"
echo "Bootloader image is fused successfully."
echo ""

# ----------------------------------------------------------
# partition card & fusing filesystem
true ${SD_UPDATE:=./tools/${HOST_ARCH}sd_update}

[[ -z $2 && ! -f "${RK_PARAMETER_TXT}" ]] && {
	echo "Not found ${RK_PARAMETER_TXT}"
	exit 1
}

${SD_UPDATE} -d /dev/${DEV_NAME} -p ${RK_PARAMETER_TXT}
if [ $? -ne 0 ]; then
	echo "Error: filesystem fusing failed, Stop."
	exit 1
fi

if ! command -v partprobe &>/dev/null; then
	sudo apt-get install parted
fi

partprobe /dev/${DEV_NAME} -s 2>/dev/null

echo "---------------------------------"
echo "All done."
