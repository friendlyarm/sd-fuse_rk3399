#!/bin/bash

TARGET_OS=$1
case ${TARGET_OS} in
friendlywrt-kernel4)
        ROMFILE=friendlywrt-kernel4-images.tgz;;
buildroot)
        ROMFILE=buildroot-images.tgz;;
debian-*|friendlycore-focal-arm64|friendlycore-lite-focal-kernel4-arm64)
        ROMFILE=${TARGET_OS%-*}-arm64-images.tgz;;
android10)
        ROMFILE=android-10-images.tgz;;
android11)
        ROMFILE=android-11-images.tgz;;
eflasher)
        ROMFILE=emmc-flasher-images.tgz;;
*)
	ROMFILE=unsupported-${TARGET_OS}.tgz
esac
echo $ROMFILE
