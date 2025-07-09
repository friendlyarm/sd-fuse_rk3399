#!/bin/bash
set -eu

function has_built_uboot() {
	if [ -f $1/uboot.img ]; then
		echo 1
	else
		echo 0
	fi
}

function has_built_kernel() {
	local KIMG=kernel.img
	if [ -f $1/${KIMG} ]; then
		echo 1
	else
		echo 0
	fi
}

function has_built_kernel_modules() {
	local OUTDIR=${2}
	local SOC=rk3399
	if [ -d ${OUTDIR}/output_${SOC}_kmodules ]; then
		echo 1
	else
		echo 0
	fi
}

function check_and_install_package() {
	local PACKAGES=
	if ! command -v mkfs.exfat &>/dev/null; then
		if [ -f /etc/os-release ]; then
			. /etc/os-release
			case "$VERSION_CODENAME" in
			noble|jammy|bookworm|bullseye)
					PACKAGES="exfatprogs exfat-fuse ${PACKAGES}"
					;;
			*)
					PACKAGES="exfat-fuse exfat-utils ${PACKAGES}"
					;;
			esac
		fi

	fi
	if ! [ -x "$(command -v simg2img)" ]; then
		if [ -f /etc/os-release ]; then
			. /etc/os-release
			case "$VERSION_CODENAME" in
			focal|jammy|noble|bookworm|bullseye)
					PACKAGES="android-sdk-libsparse-utils ${PACKAGES}"
					# PACKAGES="android-sdk-ext4-utils ${PACKAGES}"
					;;
			*)
					PACKAGES="android-tools-fsutils ${PACKAGES}"
					;;
			esac
		fi
	fi
	if ! [ -x "$(command -v swig)" ]; then
		PACKAGES="swig ${PACKAGES}"
	fi
	if ! [ -x "$(command -v git)" ]; then
		PACKAGES="git ${PACKAGES}"
	fi
	if ! [ -x "$(command -v wget)" ]; then
		PACKAGES="wget ${PACKAGES}"
	fi
	if ! [ -x "$(command -v rsync)" ]; then
		PACKAGES="rsync ${PACKAGES}"
	fi
	if ! command -v partprobe &>/dev/null; then
		PACKAGES="parted ${PACKAGES}"
	fi
	if ! command -v sfdisk &>/dev/null; then
		PACKAGES="fdisk ${PACKAGES}"
	fi
	if ! command -v resize2fs &>/dev/null; then
		PACKAGES="e2fsprogs ${PACKAGES}"
	fi
	if [ ! -z "${PACKAGES}" ]; then
		sudo apt install ${PACKAGES}
	fi
}

function check_and_install_toolchain() {
	local PACKAGES=
	local requirements=("build-essential" "make" "device-tree-compiler" "bc" "cpio" "lz4" \
		"flex" "bison" "libncurses-dev" "libssl-dev" "libelf-dev")
	for pkg in ${requirements[@]}; do
		if ! dpkg -s $pkg > /dev/null 2>&1; then
			PACKAGES="$pkg ${PACKAGES}"
		fi
	done
	if [ ! -z "${PACKAGES}" ]; then
		sudo apt install ${PACKAGES}
	fi

	case "$(uname -mpi)" in
	x86_64*)
		if [ ! -d /opt/FriendlyARM/toolchain/6.4-aarch64 ]; then
			echo "please install aarch64-gcc-6.4 first, using following commands: "
			echo "  git clone https://github.com/friendlyarm/prebuilts.git -b master --depth 1"
			echo "  cd prebuilts/gcc-x64"
			echo "  cat toolchain-6.4-aarch64.tar.gz* | sudo tar xz -C /"
			exit 1
		fi
		export PATH=/opt/FriendlyARM/toolchain/6.4-aarch64/bin/:$PATH
		return 0
		;;
	aarch64*)
		return 0
		;;
	*)
		echo "Error: Cannot build arm64 arch on $(uname -mpi) host."
		;;
	esac
	return 1
}
