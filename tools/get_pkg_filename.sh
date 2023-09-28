#!/bin/bash

TARGET_OS=$1
case ${TARGET_OS} in
friendlywrt22)
        ROMFILE=friendlywrt22-images.tgz;;
friendlywrt22-docker)
        ROMFILE=friendlywrt22-docker-images.tgz;;
friendlywrt21)
        ROMFILE=friendlywrt21-images.tgz;;
friendlywrt21-docker)
        ROMFILE=friendlywrt21-docker-images.tgz;;
friendlycore-lite-focal-kernel6-arm64)
        ROMFILE=friendlycore-lite-focal-kernel6-arm64-images.tgz;;
openmediavault-arm64)
        ROMFILE=openmediavault-arm64-images.tgz;;
eflasher)
        ROMFILE=emmc-flasher-images.tgz;;
*)
	ROMFILE=unsupported-${TARGET_OS}.tgz
esac
echo $ROMFILE
