#!/bin/bash
set -eu

[ -f ${PWD}/mk-emmc-image.sh ] || {
	echo "Error: please run at the script's home dir"
	exit 1
}

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
#----------------------------------------------------------
# local functions


IMG_SIZE=$1
TARGET_OS=$(echo ${2,,}|sed 's/\///g')

TOP=$PWD

function get_root_address_in_partmap()
{
    declare -a platfroms=("s5p4418" "s5p6818" "rk3328" "rk3399" "h3" "rk3568" "rk3588" "rk3566")
    declare -a rootfs_partition_address=(0x4400000 0x4400000 0x6000000 0x8000000 0x4000000 0x6000000 0x6000000 0x6000000)

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
        echo "${0} only support [s5p4418/s5p6818/rk3328/rk3399/h3/rk3568/rk3566/rk3588]"
        exit 1
    fi
    echo ${rootfs_partition_address[$INDEX]}
}

if [ -z ${IMG_SIZE} ]; then
    echo "miss IMG_SIZE"
    exit 1
fi

true ${PARAMETER_TPL:="${TOP}/prebuilt/parameter.template"}
PARAMETER_TXT=${TARGET_OS}/parameter.txt

if [ ! -f ${PARAMETER_TPL} ]; then
    echo "not found ${PARAMETER_TPL}"
    exit 1
fi

# If the partition layout includes an opt partition,
# it is commonly used in FriendlyWrt system with Docker pre-installed.
if grep -q "<OPT_PARTITION_ADDR>" ${PARAMETER_TPL}; then
    cp -avf ${PARAMETER_TPL} ${PARAMETER_TXT}
    # Byte to sector size
    ROOTFS_PARTITION_SIZE=`printf "0x%08x" $(($IMG_SIZE/512))`
    sed -i "s|<ROOTFS_PARTITION_SIZE>|${ROOTFS_PARTITION_SIZE}|g" ${PARAMETER_TXT}

    ROOTFS_PARTITION_ADDR=$(grep "^CMDLINE:" ${PARAMETER_TPL} | sed 's/.*<ROOTFS_PARTITION_SIZE>@//g;s/(rootfs).*//g')
    echo "ROOTFS_PARTITION_ADDR = ${ROOTFS_PARTITION_ADDR}"
    USERDATA_PARTITION_ADDR=`printf "0x%08x" $((${ROOTFS_PARTITION_ADDR}+${ROOTFS_PARTITION_SIZE}))`
    if [ $? -ne 0 ]; then
        echo "failed to get partition address of rootfs."
        exit 1
    fi
    sed -i "s|<USERDATA_PARTITION_ADDR>|${USERDATA_PARTITION_ADDR}|g" ${PARAMETER_TXT}

    # Size of the userdata partition
    USERDATA_SIZE=1073741824
    USERDATA_PARTITION_SIZE=`printf "0x%08x" $((${USERDATA_SIZE}/512))`
    sed -i "s|<USERDATA_PARTITION_SIZE>|${USERDATA_PARTITION_SIZE}|g" ${PARAMETER_TXT}

    OPT_PARTITION_ADDR=`printf "0x%08x" $((${USERDATA_PARTITION_ADDR}+${USERDATA_PARTITION_SIZE}))`
    sed -i "s|<OPT_PARTITION_ADDR>|${OPT_PARTITION_ADDR}|g" ${PARAMETER_TXT}
else
    cp -avf ${PARAMETER_TPL} ${PARAMETER_TXT}
    # Byte to sector size
    ROOTFS_PARTITION_SIZE=`printf "0x%08x" $(($IMG_SIZE/512))`
    sed -i "s|<ROOTFS_PARTITION_SIZE>|${ROOTFS_PARTITION_SIZE}|g" ${PARAMETER_TXT}

    ROOTFS_PARTITION_ADDR=$(grep "^CMDLINE:" ${PARAMETER_TPL} | sed 's/.*<ROOTFS_PARTITION_SIZE>@//g;s/(rootfs).*//g')
    USERDATA_PARTITION_ADDR=`printf "0x%08x" $((${ROOTFS_PARTITION_ADDR}+${ROOTFS_PARTITION_SIZE}))`
    if [ $? -ne 0 ]; then
        echo "failed to get partition address of rootfs."
        exit 1
    fi
    sed -i "s|<USERDATA_PARTITION_ADDR>|${USERDATA_PARTITION_ADDR}|g" ${PARAMETER_TXT}
fi
echo "generating ${PARAMETER_TXT} done."

echo 0
