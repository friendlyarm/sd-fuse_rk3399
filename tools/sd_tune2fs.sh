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
# Checking block device

if [ -z $1 ]; then
	echo "Usage: sd_tune2fs.sh <SD Reader's device>"
	exit 0
fi

if [ ! -b $1 ]; then
	echo "Error: $1: No such device"
	exit 1
fi

case $1 in
/dev/sd[a-z] | /dev/loop[0-9] | /dev/mmcblk1)
	DEV_NAME=`basename $1`
	BLOCK_CNT=`cat /sys/block/${DEV_NAME}/size` ;;&
/dev/sd[a-z])
	REMOVABLE=`cat /sys/block/${DEV_NAME}/removable` ;;
/dev/mmcblk1 | /dev/loop[0-9])
	DEV_NAME=`basename $1`p
	REMOVABLE=1 ;;
*)
	echo "Error: Unsupported SD reader"
	exit 0
esac

if [ ${REMOVABLE} -le 0 ]; then
	echo "Error: $1 is non-removable device. Stop."
	exit 1
fi

if [ -z ${BLOCK_CNT} -o ${BLOCK_CNT} -le 0 ]; then
	echo "Error: $1 is inaccessible. Stop now!"
	exit 1
fi

let DEV_SIZE=${BLOCK_CNT}/2
if [ ${DEV_SIZE} -gt 64000000 ]; then
	echo "Error: $1 size (${DEV_SIZE} KB) is too large"
	exit 1
fi

if [ ${DEV_SIZE} -le 3800000 ]; then
	echo "Error: $1 size (${DEV_SIZE} KB) is too small"
	echo "       At least 4GB SDHC card is required, please try another card."
	exit 1
fi

#----------------------------------------------------------
# Execute an action
FA_DoExec() {
	echo "==> Executing: '${@}'"
	eval $@ || exit $?
}

# ----------------------------------------------------------
# do real tasks
UUID="fa000000-3399-0000-2018-0100000000"

echo "Update ext4fs for Android on $1..."

# umount all at first
umount /dev/${DEV_NAME}* > /dev/null 2>&1

if [ -b /dev/${DEV_NAME}1 ]; then
	FA_DoExec "echo y | tune2fs /dev/${DEV_NAME}1 -U ${UUID}01 -L boot"
fi

if [ -b /dev/${DEV_NAME}2 ]; then
	FA_DoExec "echo y | tune2fs /dev/${DEV_NAME}2 -U ${UUID}02 -L system"
fi

if [ -b /dev/${DEV_NAME}3 ]; then
	FA_DoExec "echo y | tune2fs /dev/${DEV_NAME}3 -U ${UUID}03 -L cache"
fi

if [ -b /dev/${DEV_NAME}7 ]; then
	FA_DoExec resize2fs /dev/${DEV_NAME}7 -f
	FA_DoExec "echo y | tune2fs /dev/${DEV_NAME}7 -U ${UUID}07 -L userdata"

elif [ -b /dev/${DEV_NAME}4 ]; then
	FA_DoExec resize2fs /dev/${DEV_NAME}4 -f
	FA_DoExec "echo y | tune2fs /dev/${DEV_NAME}4 -U ${UUID}04 -L userdata"
fi

sync

#----------------------------------------------------------
echo "...done."

