#!/bin/bash

TARGET_OS=$(echo ${1,,}|sed 's/\///g')
case ${TARGET_OS} in
friendlywrt24)
        ROMFILE=friendlywrt24-images.tgz;;
friendlywrt24-docker)
        ROMFILE=friendlywrt24-docker-images.tgz;;
friendlywrt23)
        ROMFILE=friendlywrt23-images.tgz;;
friendlywrt23-docker)
        ROMFILE=friendlywrt23-docker-images.tgz;;
friendlywrt22)
        ROMFILE=friendlywrt22-images.tgz;;
friendlywrt22-docker)
        ROMFILE=friendlywrt22-docker-images.tgz;;
friendlywrt21)
        ROMFILE=friendlywrt21-images.tgz;;
friendlywrt21-docker)
        ROMFILE=friendlywrt21-docker-images.tgz;;
friendlycore-lite-*|debian-*|ubuntu-*|openmediavault-*|alpine-linux-*)
        ROMFILE=${TARGET_OS%-*}-arm64-images.tgz;;
eflasher)
        ROMFILE=emmc-flasher-images.tgz;;
*)
	ROMFILE=unsupported-${TARGET_OS}.tgz
esac
echo $ROMFILE
