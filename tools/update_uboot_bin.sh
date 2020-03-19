#!/bin/bash
set -eu

[ -f ${PWD}/mk-emmc-image.sh ] || {
	echo "Error: please run at the script's home dir"
	exit 1
}

# Automatically re-run script under sudo if not root
if [ $(id -u) -ne 0 ]; then
        echo "Re-running script under sudo..."
        sudo "$0" "$@"
        exit
fi

if [ $# -ne 2 ]; then
	echo "number of args must be 2"
	exit 1
fi

cp -f $1/rk3399_loader_v1.24.119.bin $2/MiniLoaderAll.bin
cp -f $1/uboot.img $2/
cp -f $1/trust.img $2/

exit $?
