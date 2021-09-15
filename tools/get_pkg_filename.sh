#!/bin/bash

TARGET_OS=$1
case ${TARGET_OS} in
friendlywrt-kernel4)
        ROMFILE=friendlywrt-kernel4-images.tgz;;
friendlycore-focal-arm64)
        ROMFILE=friendlycore-focal-arm64-images.tgz;;
friendlycore-lite-focal-kernel4-arm64)
        ROMFILE=friendlycore-lite-focal-kernel4-arm64-images.tgz;;
android10)
        ROMFILE=android-10-images.tgz;;
eflasher)
        ROMFILE=emmc-flasher-images.tgz;;
*)
	ROMFILE=unsupported-${TARGET_OS}.tgz
esac
echo $ROMFILE
