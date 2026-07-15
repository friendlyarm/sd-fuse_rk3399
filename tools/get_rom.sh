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

# ----------------------------------------------------------
# base setup

SDFUSE_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if [ -f "${SDFUSE_ROOT}/.use-local-r2" ]; then
    BASE_URL=http://cdn.local/friendlyelec-cdn/os-images
else
    BASE_URL=https://downloads.friendlyelec.com/os-images
fi
BOARD=rk3399/images
OUT_DIR=out
TARGET_OS=$(echo ${1,,}|sed 's/\///g')
ROMFILE=`./tools/get_pkg_filename.sh ${TARGET_OS}`
if [ -z ${ROMFILE} ]; then
	echo "Usage: $0 <img dir>"
	exit 1
fi

#----------------------------------------------------------
# local functions

function FA_DoExec() {
	echo "> ${@}"
	eval $@
}

function download_file()
{
	local url=${BASE_URL}/${BOARD}/$1

	if [ -z $1 ]; then
		echo "Error downloading file: $1"
		exit 1
	fi

	if [ -f ${OUT_DIR}/$1 ]; then
		rm -fv ${OUT_DIR}/$1
	fi

	if ! FA_DoExec wget -P ${OUT_DIR} ${url}; then
		echo "Error downloading file: $1"
		exit 1
	fi

	return 0
}

#----------------------------------------------------------
# download image and verify it

mkdir -p ${OUT_DIR}

download_file ${ROMFILE}.sha256

NEED_DL=1
if [ -f ${OUT_DIR}/${ROMFILE} ]; then
	if (cd ${OUT_DIR} && sha256sum -c ${ROMFILE}.sha256) >/dev/null 2>&1; then
		NEED_DL=0
	fi
fi

# skip if main file exist and sha256sum check OK
if [ ${NEED_DL} -ne 0 ]; then
	download_file ${ROMFILE}
fi

if ! (cd ${OUT_DIR} && sha256sum -c ${ROMFILE}.sha256); then
	echo "Error in downloaded file, please try again, or download it by"
	echo "browser or other tools, URL is:"
	echo "  ${BASE_URL}/${BOARD}/${ROMFILE}"
	echo "  ${BASE_URL}/${BOARD}/${ROMFILE}.sha256"
	exit 1
fi

#----------------------------------------------------------
# extract

mkdir -p ${TARGET_OS}

if [ -f ${OUT_DIR}/${ROMFILE} ]; then
	XOPTS="-C ${TARGET_OS} --strip-components=1"
	FA_DoExec tar xzvf ${OUT_DIR}/${ROMFILE} ${XOPTS} || exit 1
fi
