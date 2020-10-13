#!/bin/bash
set -eu

[ -f ${PWD}/mk-emmc-image.sh ] || {
	echo "Error: please run at the script's home dir"
	exit 1
}

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
#----------------------------------------------------------
# local functions

SOC=rk3399
IMG_SIZE=$1
TARGET_OS=$2

TOP=$PWD

function get_root_address_in_partmap()
{
    declare -a platfroms=("s5p4418" "s5p6818" "rk3399" "h3")
    declare -a rootfs_partition_address=(0x4400000 0x4400000 0x6000000 0x4000000)

    INDEX=0
    FOUND=0
    for (( i=0; i<${#platfroms[@]}; i++ ));
    do
            if [ "x${platfroms[$i]}" = "x${1}" ]; then
                    INDEX=$i
                    FOUND=1
                    break
            fi
    done
    if [ ${FOUND} == 0 ]; then
        echo "${0} only support [s5p4418/s5p6818/rk3399/h3]"
        exit 1
    fi
    echo ${rootfs_partition_address[$INDEX]}
}

if [ -z ${IMG_SIZE} ]; then
    echo "miss IMG_SIZE"
    exit 1
fi

SRC_PARAM4SD_TPL=${TOP}/prebuilt/param4sd.template
SRC_PARAMETER_TPL=${TOP}/prebuilt/parameter.template
SRC_PARTMAP_TPL=${TOP}/prebuilt/partmap.template


DEST_PARAM4SD_TXT=${TARGET_OS}/param4sd.txt
DEST_PARAMETER_TXT=${TARGET_OS}/parameter.txt
DEST_PARTMAP_TXT=${TARGET_OS}/partmap.txt

if [ -f ${SRC_PARAM4SD_TPL} ]; then
    cp -avf ${SRC_PARAM4SD_TPL} ${DEST_PARAM4SD_TXT}
    # Byte to sector size
    ROOTFS_PARTITION_SIZE=`printf "0x%X" $(($IMG_SIZE/512))`
    sed -i "s|<ROOTFS_PARTITION_SIZE>|${ROOTFS_PARTITION_SIZE}|g" ${DEST_PARAM4SD_TXT}

    ROOTFS_PARTITION_ADDR=0x00030000
    USERDATA_PARTITION_ADDR=`printf "0x%X" $((${ROOTFS_PARTITION_ADDR}+${ROOTFS_PARTITION_SIZE}))`
    sed -i "s|<USERDATA_PARTITION_ADDR>|${USERDATA_PARTITION_ADDR}|g" ${DEST_PARAM4SD_TXT}
fi
echo "generating ${DEST_PARAM4SD_TXT} done."

if [ -f ${SRC_PARAMETER_TPL} ]; then
    cp -avf ${SRC_PARAMETER_TPL} ${DEST_PARAMETER_TXT}
    # Byte to sector size
    ROOTFS_PARTITION_SIZE=`printf "0x%08x" $(($IMG_SIZE/512))`
    sed -i "s|<ROOTFS_PARTITION_SIZE>|${ROOTFS_PARTITION_SIZE}|g" ${DEST_PARAMETER_TXT}

    ROOTFS_PARTITION_ADDR=$(grep "^CMDLINE:" ${SRC_PARAMETER_TPL} | sed 's/.*SIZE>@//g;s/(rootfs).*//g')
    USERDATA_PARTITION_ADDR=`printf "0x%08x" $((${ROOTFS_PARTITION_ADDR}+${ROOTFS_PARTITION_SIZE}))`
    if [ $? -ne 0 ]; then
        echo "failed to get partition address of rootfs."
        exit 1
    fi
    sed -i "s|<USERDATA_PARTITION_ADDR>|${USERDATA_PARTITION_ADDR}|g" ${DEST_PARAMETER_TXT}
fi
echo "generating ${DEST_PARAMETER_TXT} done."

if [ -f ${SRC_PARTMAP_TPL} ]; then
    cp -avf ${SRC_PARTMAP_TPL} ${DEST_PARTMAP_TXT}
    ROOTFS_PARTITION_SIZE=`printf "0x%X" ${IMG_SIZE}`
    sed -i "s|<ROOTFS_PARTITION_SIZE>|${ROOTFS_PARTITION_SIZE}|g" ${DEST_PARTMAP_TXT}
    ROOTFS_PARTITION_ADDR=$(get_root_address_in_partmap ${SOC})
    USERDATA_PARTITION_ADDR=`printf "0x%X" $((${ROOTFS_PARTITION_ADDR}+${ROOTFS_PARTITION_SIZE}))`
    sed -i "s|<USERDATA_PARTITION_ADDR>|${USERDATA_PARTITION_ADDR}|g" ${DEST_PARTMAP_TXT}
fi

echo "generating ${DEST_PARTMAP_TXT} done."
echo 0
