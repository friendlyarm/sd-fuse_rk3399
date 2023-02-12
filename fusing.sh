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
# ----------------------------------------------------------
# Checking device for fusing

if [ $# -eq 0 ]; then
	echo "Usage: $0 DEVICE <friendlycore-arm64|friendlydesktop-arm64|buildroot|lubuntu|android7|android8|eflasher>"
	exit 0
fi

case $1 in
/dev/sd[a-z] | /dev/loop[0-9]* | /dev/mmcblk[0-9]*)
	if [ ! -e $1 ]; then
		echo "Error: $1 does not exist."
		exit 1
	fi
	DEV_NAME=`basename $1`
	BLOCK_CNT=`cat /sys/block/${DEV_NAME}/size` ;;&
/dev/sd[a-z])
	DEV_PART=${DEV_NAME}1
	REMOVABLE=`cat /sys/block/${DEV_NAME}/removable` ;;
/dev/mmcblk[0-9]* | /dev/loop[0-9]*)
	DEV_PART=${DEV_NAME}p1
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

# ----------------------------------------------------------
# Get target OS

true ${TARGET_OS:=${2,,}}

RKPARAM=$(dirname $0)/${TARGET_OS}/parameter.txt
RKPARAM2=$(dirname $0)/${TARGET_OS}/param4sd.txt
case ${2,,} in
friendlycore-arm64 | friendlydesktop-arm64 | buildroot | android7 | android8 | lubuntu)
	;;
eflasher)
	[ -f ./${TARGET_OS}/idbloader.img ] && touch ${RKPARAM} ;;
*)
	echo "Error: Unsupported target OS: ${TARGET_OS}"
	exit -1;;
esac

if [ -f "${RKPARAM}" -o -f "${RKPARAM2}" ]; then
        echo ""
else
	ROMFILE=`./tools/get_pkg_filename.sh ${TARGET_OS}`
	cat << EOF
Warn: Image not found for ${TARGET_OS}
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

	./tools/get_rom.sh ${TARGET_OS} || exit 1
fi

# Automatically re-run script under sudo if not root
if [ $(id -u) -ne 0 ]; then
	echo "Re-running script under sudo..."
	sudo --preserve-env "$0" "$@"
	exit
fi

# ----------------------------------------------------------
# Get host machine
ARCH=
if uname -mpi | grep aarch64 >/dev/null; then
#	EMMC=.emmc
	ARCH=aarch64/
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
set +e
umount /dev/${DEV_NAME}* > /dev/null 2>&1
set -e
if [ ! -f ${TARGET_OS}/idbloader.img -a ! -f ${TARGET_OS}/trust.img ]; then
	fusing_bin ${BOOT_DIR}/idbloader.img  64
	fusing_bin ${BOOT_DIR}/uboot.img      16384
	fusing_bin ${BOOT_DIR}/trust.img      24576
fi

#<Message Display>
echo "---------------------------------"
echo "Bootloader image is fused successfully."
echo ""

# ----------------------------------------------------------
# partition card & fusing filesystem

true ${SD_UPDATE:=$(dirname $0)/tools/sd_update}

[[ -z $2 && ! -f "${RKPARAM}" ]] && exit 0

echo "---------------------------------"
echo "${TARGET_OS^} filesystem fusing"
echo "Image root: `dirname ${RKPARAM}`"
echo

PARTMAP=$(dirname $0)/${TARGET_OS}/partmap.txt
PARAM4SD=$(dirname $0)/${TARGET_OS}/param4sd.txt

# ----------------------------------------------------------
# Prepare image for sd raw img
#     emmc boot: need parameter.txt, do not need partmap.txt
#     sdraw: all need parameter.txt and partmap.txt

if [ ! -f "${PARTMAP}" ]; then
	if [ -d ${TARGET_OS}/sd-boot ]; then
      		(cd ${TARGET_OS}/sd-boot && { \
               		cp partmap.txt ../; \
       		})
       fi	
fi

if [ ! -f "${PARAM4SD}" ]; then
	if [ -d ${TARGET_OS}/sd-boot ]; then
	       (cd ${TARGET_OS}/sd-boot && { \
        	       cp param4sd.txt ../; \
	       })
       fi
fi

if [ ! -f "${PARTMAP}" ]; then
		echo "File not found: ${PARTMAP}, please download the latest version of the image files from http://dl.friendlyarm.com/nanopct4"
		exit 1
fi

if [ ! -f "${PARAM4SD}" ]; then
		echo "File not found: ${PARAM4SD}, please download the latest version of the image files from http://dl.friendlyarm.com/nanopct4"
		exit 1
fi

# write ext4 image
${SD_UPDATE} -d /dev/${DEV_NAME} -p ${PARTMAP}
if [ $? -ne 0 ]; then
	echo "Error: filesystem fusing failed, Stop."
	exit 1
fi

if [ -z ${ARCH} ]; then
	partprobe /dev/${DEV_NAME} -s 2>/dev/null
fi
if [ $? -ne 0 ]; then
	echo "Warning: Re-reading the partition table failed"

else
	case ${TARGET_OS} in
	debian* | buildroot* | friendlycore* | friendlydesktop* | lubuntu* | friendlywrt*)
		sleep 1
		resize2fs -f /dev/${DEV_PART};;
	esac
fi

echo "---------------------------------"
echo "${TARGET_OS^} is fused successfully."
echo "All done."

