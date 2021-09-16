#!/bin/bash

TARGET_OS=$1
case ${TARGET_OS} in
friendlywrt)
        ROMFILE=friendlywrt-images.tgz;;
friendlycore-lite-focal-kernel5-arm64)
        ROMFILE=friendlycore-lite-focal-kernel5-arm64-images.tgz;;
eflasher)
        ROMFILE=emmc-flasher-images.tgz;;
*)
	ROMFILE=unsupported-${TARGET_OS}.tgz
esac
echo $ROMFILE
