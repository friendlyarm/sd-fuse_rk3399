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
function usage() {
       echo "Usage: $0 <friendlycore-lite-focal-arm64|friendlywrt>"
       exit 0
}

if [ $# -eq 0 ]; then
    usage
fi

# ----------------------------------------------------------
# Get platform, target OS

true ${SOC:=rk3399}
true ${TARGET_OS:=${1,,}}

case ${TARGET_OS} in
friendlycore-lite-focal-arm64|friendlywrt )
	;;
*)
	echo "Error: Unsupported target OS: ${TARGET_OS}"
	exit 0
esac


# Automatically re-run script under sudo if not root
if [ $(id -u) -ne 0 ]; then
	echo "Re-running script under sudo..."
	sudo "$0" "$@"
	exit
fi



# ----------------------------------------------------------
# Create zero file

if [ $# -eq 2 ]; then
	RAW_FILE=$2
    case ${TARGET_OS} in
    friendlycore-arm64)
        RAW_SIZE_MB=7800 ;;
    friendlywrt)
        RAW_SIZE_MB=1000 ;;
    friendlydesktop-arm64)
        RAW_SIZE_MB=7800 ;;
    friendlycore-focal-arm64)
        RAW_SIZE_MB=7800 ;;
    friendlycore-lite-focal-arm64)
        RAW_SIZE_MB=7800 ;;
    debian)
        RAW_SIZE_MB=7800 ;;
    lubuntu)
        RAW_SIZE_MB=7800 ;;
    eflasher)
        RAW_SIZE_MB=7800 ;;
    buildroot)
        RAW_SIZE_MB=4000 ;;
    *)
        RAW_SIZE_MB=7800 ;;
    esac
else
	case ${TARGET_OS} in
	friendlycore-arm64)
		RAW_FILE=${SOC}-sd-friendlycore-bionic-4.4-arm64-$(date +%Y%m%d).img
		RAW_SIZE_MB=7800 ;;
	friendlywrt)
		RAW_FILE=${SOC}-sd-friendlywrt-5.10-arm64-$(date +%Y%m%d).img
		RAW_SIZE_MB=1000 ;;
	friendlydesktop-arm64)
		RAW_FILE=${SOC}-sd-friendlydesktop-bionic-4.4-arm64-$(date +%Y%m%d).img
		RAW_SIZE_MB=7800 ;;
    friendlycore-focal-arm64)
        RAW_FILE=${SOC}-sd-friendlycore-focal-5.10-arm64-$(date +%Y%m%d).img
        RAW_SIZE_MB=7800 ;; 
    friendlycore-lite-focal-arm64)
        RAW_FILE=${SOC}-sd-friendlycore-lite-focal-5.10-arm64-$(date +%Y%m%d).img
        RAW_SIZE_MB=7800 ;; 
	debian)
		RAW_FILE=${SOC}-sd-debian9-4.4-armhf-$(date +%Y%m%d).img
		RAW_SIZE_MB=7800 ;;
	lubuntu)
		RAW_FILE=${SOC}-sd-lubuntu-desktop-xenial-4.4-armhf-$(date +%Y%m%d).img
		RAW_SIZE_MB=7800 ;;
	eflasher)
		RAW_FILE=${SOC}-eflasher-$(date +%Y%m%d).img
		RAW_SIZE_MB=7800 ;;
	buildroot)
	    RAW_FILE=${SOC}-sd-buildroot-linux-4.4-arm64-$(date +%Y%m%d).img
	    RAW_SIZE_MB=4000 ;;
    android10)
        RAW_FILE=${SOC}-sd-android10-$(date +%Y%m%d).img
        RAW_SIZE_MB=7800 ;;
	*)
		RAW_FILE=${SOC}-${TARGET_OS}-sd4g-$(date +%Y%m%d).img
		RAW_SIZE_MB=7800 ;;
	esac
fi

OUT=out
if [ ! -d $OUT ]; then
	echo "path not found: $PWD/$OUT"
	exit 1
fi
RAW_FILE=${OUT}/${RAW_FILE}

BLOCK_SIZE=1024
let RAW_SIZE=(${RAW_SIZE_MB}*1000*1000)/${BLOCK_SIZE}

echo "Creating RAW image: ${RAW_FILE} (${RAW_SIZE_MB} MB)"
echo "---------------------------------"


if [ -f "${RAW_FILE}" ]; then
	rm -f ${RAW_FILE}
fi

dd if=/dev/zero of=${RAW_FILE} bs=${BLOCK_SIZE} count=0 \
	seek=${RAW_SIZE} || exit 1

sfdisk -u S -L -q ${RAW_FILE} 2>/dev/null << EOF
2048,,0x0C,-
EOF

if [ $? -ne 0 ]; then
	echo "Error: ${RAW_FILE}: Creating RAW file failed"
	exit 1
fi

# ----------------------------------------------------------
# Setup loop device

LOOP_DEVICE=$(losetup -f)

echo "Using device: ${LOOP_DEVICE}"

if losetup ${LOOP_DEVICE} ${RAW_FILE}; then
	USE_KPARTX=1
	PART_DEVICE=/dev/mapper/`basename ${LOOP_DEVICE}`
	sleep 1
else
	echo "Error: attaching ${LOOP_DEVICE} failed, stop now."
	rm ${RAW_FILE}
	exit 1
fi

# ----------------------------------------------------------
# Fusing all

true ${SD_FUSING:=$(dirname $0)/fusing.sh}

${SD_FUSING} ${LOOP_DEVICE} ${TARGET_OS}
RET=$?

if [ "x${TARGET_OS}" = "xeflasher" ]; then
	mkfs.exfat ${LOOP_DEVICE}p1 -n FriendlyARM
fi

# cleanup
losetup -d ${LOOP_DEVICE}

if [ ${RET} -ne 0 ]; then
	echo "Error: ${RAW_FILE}: Fusing image failed, cleanup"
	rm -f ${RAW_FILE}
	exit 1
fi

echo "---------------------------------"
echo "RAW image successfully created (`date +%T`)."
ls -l ${RAW_FILE}
echo "Tip: You can compress it to save disk space."

