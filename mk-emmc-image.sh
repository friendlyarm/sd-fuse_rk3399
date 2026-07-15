#!/bin/bash
set -eu

# Copyright (C) Guangzhou FriendlyElec Computer Tech. Co., Ltd.
# (https://www.friendlyelec.com)
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
       echo "Usage: $0 <img dir> [img filename] [options]"
       echo "    examples:"
       echo "        ./mk-emmc-image.sh friendlywrt23 filename=myimg-emmc.img autostart=yes"
       echo "        ./mk-emmc-image.sh friendlywrt23 autostart=yes"
       echo "        ./mk-emmc-image.sh friendlywrt23"
       exit 0
}

if [ $# -eq 0 ]; then
    usage
fi

. tools/util.sh
check_and_install_package

# ----------------------------------------------------------
# Get platform, target OS

true ${SOC:=rk3399}
true ${TARGET_OS:=$(echo ${1,,}|sed 's/\///g')}

case ${TARGET_OS} in
friendlycore* | ubuntu-*-core-arm64 | debian-*-core-arm64 | openmediavault-* | alpine-linux-* | arch-linux-* | friendlywrt*)
        ;;
*)
        echo "Error: Unsupported target OS: ${TARGET_OS}"
        exit 0
esac

download_img() {
    local RKPARAM=$(dirname $0)/${1}/parameter.txt
    if [ -f "${RKPARAM}" ]; then
        echo ""
    else
	ROMFILE=`./tools/get_pkg_filename.sh ${1}`
        cat << EOF
Warn: Image directory not found: ${1}
Do you want to download it now? (Y/N):
EOF
        case "${SDFUSE_NONINTERACTIVE:-}" in y|Y|yes|YES|1|true|TRUE) USER_REPLY=y; echo "$USER_REPLY (auto: SDFUSE_NONINTERACTIVE=$SDFUSE_NONINTERACTIVE)";; esac
        while [ -z "${USER_REPLY:-}" ] && read -r -n 1 -t 3600 -s USER_REPLY; do
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

download_img ${TARGET_OS}
download_img eflasher

# Automatically re-run script under sudo if not root
if [ $(id -u) -ne 0 ]; then
	echo "Re-running script under sudo..."
	sudo --preserve-env "$0" "$@"
	exit
fi

true ${RAW_SIZE_MB:=0}
RAW_SIZE_MB=${RAW_SIZE_MB} ./mk-sd-image.sh eflasher && \
	./tools/fill_img_to_eflasher out/${SOC}-eflasher-$(date +%Y%m%d).img ${SOC} $@ && {
		rm -f out/${SOC}-eflasher-$(date +%Y%m%d).img
		mkdir -p out/images-for-eflasher
		tar czf out/images-for-eflasher/${TARGET_OS}-images.tgz ${TARGET_OS}
		echo "all done."
}
