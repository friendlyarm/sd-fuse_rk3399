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

# ----------------------------------------------------------
# base setup

BASE_URL=http://112.124.9.243/dvdfiles
OPT_URL=http://wiki.friendlyarm.com/download/
BOARD=RK3399/images-for-eflasher

TARGET_OS=$(echo ${1,,}|sed 's/\///g')
ROMFILE=`./tools/get_pkg_filename.sh ${TARGET_OS}`
if [ -z ${ROMFILE} ]; then
	echo "Usage: $0 <${SUPPORTED_OS}|eflasher>"
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

	if [ -f $1 ]; then
		rm -fv $1
	fi

	FA_DoExec wget --spider --tries=1 ${url}
	if [[ "$?" != 0 ]]; then
		url=${OPT_URL}/${BOARD}/$1
	fi

	FA_DoExec wget ${url}
	if [[ "$?" != 0 ]]; then
		echo "Error downloading file: $1"
		exit 1
	fi

	return 0
}

#----------------------------------------------------------
# download image and verify it

download_file ${ROMFILE}.hash.md5

if [ -f ${ROMFILE} ]; then
	md5sum -c ${ROMFILE}.hash.md5 >/dev/null 2>&1
	NEED_DL=$?
else
	NEED_DL=1
fi

# skip if main file exist and md5sum check OK
if [ ${NEED_DL} -ne 0 ]; then
	download_file ${ROMFILE}
fi

md5sum -c ${ROMFILE}.hash.md5
if [[ "$?" != 0 ]]; then
	echo "Error in downloaded file, please try again, or download it by"
	echo "browser or other tools, URL is:"
	echo "  ${BASE_URL}/${BOARD}/${ROMFILE}"
	echo "  ${BASE_URL}/${BOARD}/${ROMFILE}.hash.md5"
	exit 1
fi

#----------------------------------------------------------
# extract

mkdir -p ${TARGET_OS}

if [ -f ${ROMFILE} ]; then
	XOPTS="-C ${TARGET_OS} --strip-components=1"
	FA_DoExec tar xzvf ${ROMFILE} ${XOPTS} || exit 1
fi
