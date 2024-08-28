#!/bin/bash
set -eu

if [ $# -lt 2 ]; then
	echo "Usage: $0 <rootfs dir> <img dir>"
    echo "example:"
    echo "    ./tools/extract-rootfs-tar.sh rootfs-ubuntu-focal-desktop-arm64.tgz"
    echo "    ./build-rootfs-img.sh ubuntu-focal-desktop-arm64/rootfs ubuntu-focal-desktop-arm64"
	exit 0
fi

TOP=$PWD
ROOTFS_DIR=$1
TARGET_OS=$(echo ${2,,}|sed 's/\///g')
IMG_FILE=$TARGET_OS/rootfs.img
if [ $# -eq 3 ]; then
	IMG_SIZE=$3
else
	IMG_SIZE=0
fi
true ${FS_TYPE:=ext4}

if [ ! -d ${ROOTFS_DIR} ]; then
    echo "path '${ROOTFS_DIR}' not found."
    exit 1
fi

# ----------------------------------------------------------
# Get host machine arch
HOST_ARCH=
if uname -mpi | grep aarch64 >/dev/null; then
    HOST_ARCH="aarch64/"
fi

# Automatically re-run script under sudo if not root
if [ $(id -u) -ne 0 ]; then
    echo "Re-running script under sudo..."
    sudo --preserve-env "$0" "$@"
    exit
fi

# Clean up temporary files
clean_rootfs() {
    (cd $1 && {
        # remove machine-id, the macaddress will be gen via it
        [ -f etc/machine-id ] && > etc/machine-id
        [ -f var/lib/dbus/machine-id ] && {
            rm -f var/lib/dbus/machine-id
            ln -s /etc/machine-id var/lib/dbus/machine-id
        }
        rm -f etc/pointercal
        rm -f etc/fs.resized
        rm -f etc/friendlyelec-release
        rm -f root/running-state-file
        rm -f etc/firstuse
        rm -f var/cache/apt/archives/lock
        rm -f var/lib/dpkg/lock
        rm -f var/lib/dpkg/lock-frontend
        rm -f var/cache/apt/archives/*.deb
        [ -f etc/udev/rules.d/70-persistent-net.rules ] && cat /dev/null > etc/udev/rules.d/70-persistent-net.rules
        rm -rf var/log/journal/*
        [ -d ./tmp ] && find ./tmp -exec rm -rf {} +
        mkdir -p ./tmp
        chmod 1777 ./tmp
        if [ -d ./var/lib/apt/lists ]; then
            PERM=`grep "^_apt" ./etc/passwd | cut -d':' -f3`
            if [ -e ./var/lib/apt/lists ]; then
                [ -z ${PERM} ] || chown -R ${PERM}.0 ./var/lib/apt/lists
            fi
            if [ -e ./var/cache/apt/archives/partial ]; then
                [ -z ${PERM} ] || chown -R ${PERM}.0 ./var/cache/apt/archives/partial
            fi
        fi
        [ -d var/log ] && find var/log -type f -delete
        [ -d var/tmp ] && find var/tmp -type f -delete
        find -name .bash_history -type f -exec cp /dev/null {} \;
        [ -e var/lib/systemd ] && touch var/lib/systemd/clock
        [ -e var/lib/private/systemd/timesync ] && touch var/lib/private/systemd/timesync/clock
        if [ -d var/lib/NetworkManager/ ]; then
            rm -fr var/lib/NetworkManager/dhclient*
            rm -fr var/lib/NetworkManager/secret_key
            rm -fr var/lib/NetworkManager/timestamps
        fi
        (cd dev && find . ! -type d -exec rm {} \;)
    })
}
clean_rootfs ${ROOTFS_DIR}

make_ext4_img() {
    local RET=0
    local MKFS_PID=
    local MKFS="${TOP}/tools/${HOST_ARCH}mke2fs"
    local MKFS_OPTS="-E android_sparse -t ext4 -L rootfs -M /root -b 4096"

    case ${TARGET_OS} in
    friendlywrt* | buildroot*)
        # set default uid/gid to 0
        MKFS_OPTS="-0 ${MKFS_OPTS}"
        ;;
    *)
        ;;
    esac
    if [ ${IMG_SIZE} -le 0 ]; then
        # calc image size
        IMG_SIZE=$(((`du -s -B64M ${ROOTFS_DIR} | cut -f1` + 3) * 1024 * 1024 * 64))
        IMG_BLK=$((${IMG_SIZE} / 4096))
        INODE_SIZE=$((`find ${ROOTFS_DIR} | wc -l` + 128))
        # make fs
        [ -f ${IMG_FILE} ] && rm -f ${IMG_FILE}
        set +e
        MKE2FS_CONFIG="${TOP}/tools/mke2fs.conf" ${MKFS} -N ${INODE_SIZE} ${MKFS_OPTS} -d ${ROOTFS_DIR} ${IMG_FILE} ${IMG_BLK} &
        MKFS_PID=$!
        wait $MKFS_PID
        RET=$?
        set -e
    else
        IMG_BLK=$((${IMG_SIZE} / 4096))
        INODE_SIZE=$((`find ${ROOTFS_DIR} | wc -l` + 128))
        [ -f ${IMG_FILE} ] && rm -f ${IMG_FILE}
        set +e
        MKE2FS_CONFIG="${TOP}/tools/mke2fs.conf" ${MKFS} -N ${INODE_SIZE} ${MKFS_OPTS} -d ${ROOTFS_DIR} ${IMG_FILE} ${IMG_BLK} &
        MKFS_PID=$!
        wait $MKFS_PID
        RET=$?
        set -e
    fi
    if [ $RET -ne 0 ]; then
        oom_log=$(dmesg | tail -n 50 | grep -i 'killed process')
        if echo "$oom_log" | grep -q "Killed process ${MKFS_PID}"; then
            echo "Error: failed to generate rootfs.img, mke2fs was killed by oom-killer, please ensure that there is sufficient system memory to execute this program."
        else
            echo "Error: failed to generate rootfs.img, mke2fs failed with exit code ${RET}"
        fi
        exit $RET
    fi
}

make_btrfs_img() {
    local RET=0
    local MKFS_PID=
    if [ ${IMG_SIZE} -le 0 ]; then
        IMG_SIZE=$(((`du -s -B64M ${ROOTFS_DIR} | cut -f1` + 3) * 1024 * 1024 * 64))
        [ -f ${IMG_FILE} ] && rm -f ${IMG_FILE}
    fi

    truncate -s ${IMG_SIZE} ${IMG_FILE}
    set +e
    mkfs.btrfs -L rootfs ${IMG_FILE}
    RET=$?
    set -e
    if [ $RET -ne 0 ]; then
        echo "Error: failed to generate rootfs.img, mkfs.btrfs failed with exit code ${RET}"
        exit $RET
    fi

    TMPDIR=$(mktemp -d)
    mount -o loop ${IMG_FILE} ${TMPDIR}
    (cd ${ROOTFS_DIR} && {
        case ${TARGET_OS} in
        friendlywrt* | buildroot*)
            # set default uid/gid to 0
            tar --numeric-owner -cvpf - * 2>/dev/null | tar --owner=0 --group=0 --numeric-owner --numeric-owner -xpf - -C ${TMPDIR}
            RET=$?
            ;;
        *)
            tar --same-owner --numeric-owner -cvpf - * 2>/dev/null | tar --same-owner --numeric-owner -xpf - -C ${TMPDIR}
            RET=$?
            ;;
        esac
    })
    umount ${TMPDIR}
    if [ $RET -ne 0 ]; then
        echo "Error: failed to copy files to rootfs.img"
        exit $RET
    fi
}

if [ "${FS_TYPE}" = "ext4" ]; then
    make_ext4_img
    if [ ${TARGET_OS} != "eflasher" ]; then
        case ${TARGET_OS} in
        openmediavault-*)
            # disable overlayfs for openmediavault
            cp ${TOP}/prebuilt/parameter-plain.txt ${TOP}/${TARGET_OS}/parameter.txt
            ;;
        *)
            ${TOP}/tools/generate-partmap-txt.sh ${IMG_SIZE} ${TARGET_OS}
            ;;
        esac
    fi
elif [ "${FS_TYPE}" = "btrfs" ]; then
	if ! command -v mkfs.btrfs &>/dev/null; then
		apt-get install btrfs-progs
	fi
    make_btrfs_img
    if [ ${TARGET_OS} != "eflasher" ]; then
        # disable overlayfs for btrfs
        cp ${TOP}/prebuilt/parameter-plain.txt ${TOP}/${TARGET_OS}/parameter.txt
		# The difference between dtbo-plain.img and dtbo.img is that
		# dtbo-plain.img does not use overlayfs
		# and does not specify the data= parameter in the boot arguments.
		# Additionally, the file system type is set to auto-detect instead of being fixed to ext4.
		cp ${TOP}/prebuilt/dtbo-plain.img ${TOP}/${TARGET_OS}/dtbo.img
    fi
else
    echo "unknow FS_TYPE: ${FS_TYPE}."
    exit 1
fi

echo "generating ${IMG_FILE} done."
echo 0
