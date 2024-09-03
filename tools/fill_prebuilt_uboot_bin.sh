#!/bin/bash
set -eu

[ -f ${PWD}/mk-emmc-image.sh ] || {
	echo "Error: please run at the script's home dir"
	exit 1
}

if [ $# -ne 1 ]; then
	echo "number of args must be 1"
	exit 1
fi

cp -f prebuilt/MiniLoaderAll.bin $1/
[ $? -ne 0 ] && exit $?
cp -f prebuilt/uboot.img $1/
[ $? -ne 0 ] && exit $?
