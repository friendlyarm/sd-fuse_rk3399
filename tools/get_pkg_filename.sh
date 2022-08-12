#!/bin/bash

TARGET_OS=$1
case ${TARGET_OS} in
debian-buster-desktop-arm64)
        ROMFILE=debian-buster-desktop-arm64-images.tgz;;
eflasher)
        ROMFILE=emmc-flasher-images.tgz;;
*)
	ROMFILE=unsupported-${TARGET_OS}.tgz
esac
echo $ROMFILE
