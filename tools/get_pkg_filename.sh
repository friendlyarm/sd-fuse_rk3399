#!/bin/bash

TARGET_OS=$1
case ${TARGET_OS} in
buildroot)
        ROMFILE=buildroot-images.tgz;;
debian)
        ROMFILE=debian-images.tgz;;
android7)
        ROMFILE=android-nougat-images.tgz;;
friendlywrt)
        ROMFILE=friendlywrt-images.tgz;;
android8)
        ROMFILE=android-oreo-images.tgz;;
friendlycore-arm64)
        ROMFILE=friendlycore-arm64-images.tgz;;
friendlydesktop-arm64)
        ROMFILE=friendlydesktop-arm64-images.tgz;;
lubuntu)
        ROMFILE=lubuntu-desktop-images.tgz;;
eflasher)
        ROMFILE=emmc-flasher-images.tgz;;
*)
	ROMFILE=
esac
echo $ROMFILE
