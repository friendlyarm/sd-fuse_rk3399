#!/bin/bash
set -eu

if [ $# -lt 2 ]; then
	echo "Usage: $0 <rootfs dir> <img dir> "
    echo "example:"
    echo "    tar xvzf NETDISK/RK3399/rootfs/rootfs-friendlycore-arm64.tgz"
    echo "    ./build-rootfs-img.sh friendlycore-arm64 /rootfs friendlycore-arm64"
	exit 0
fi

ROOTFS_DIR=$1
TARGET_OS=$(echo ${2,,}|sed 's/\///g')
IMG_FILE=$TARGET_OS/rootfs.img
if [ $# -eq 3 ]; then
	IMG_SIZE=$3
else
	IMG_SIZE=0
fi

# ----------------------------------------------------------
# Get host machine arch
HOST_ARCH=
if uname -mpi | grep aarch64 >/dev/null; then
    HOST_ARCH="aarch64/"
fi

TOP=$PWD
export MKE2FS_CONFIG="${TOP}/tools/mke2fs.conf"
if [ ! -f ${MKE2FS_CONFIG} ]; then
    echo "error: ${MKE2FS_CONFIG} not found."
    exit 1
fi
true ${MKFS:="${TOP}/tools/${HOST_ARCH}mke2fs"}

if [ ! -d ${ROOTFS_DIR} ]; then
    echo "path '${ROOTFS_DIR}' not found."
    exit 1
fi

# Automatically re-run script under sudo if not root
if [ $(id -u) -ne 0 ]; then
    echo "Re-running script under sudo..."
    sudo --preserve-env "$0" "$@"
    exit
fi

MKFS_OPTS="-E android_sparse -t ext4 -L rootfs -M /root -b 4096"
case ${TARGET_OS} in
friendlywrt* | buildroot*)
    # set default uid/gid to 0
    MKFS_OPTS="-0 ${MKFS_OPTS}"
    ;;
*)
    ;;
esac

clean_rootfs() {
    (cd $1 && {
        # remove machine-id, the macaddress will be gen via it
        [ -f etc/machine-id ] && > etc/machine-id
        [ -f var/lib/dbus/machine-id ] && {
            rm -f var/lib/dbus/machine-id
            ln -s /etc/machine-id var/lib/dbus/machine-id
        }
        rm -f etc/friendlyelec-release
        rm -f root/running-state-file
        rm -f etc/firstuse
        rm -f var/lib/dpkg/lock
        rm -f var/lib/dpkg/lock-frontend
        rm -f var/cache/apt/archives/lock
        rm -f var/cache/apt/archives/*.deb
        [ -f etc/udev/rules.d/70-persistent-net.rules ] && cat /dev/null > etc/udev/rules.d/70-persistent-net.rules
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

if [ ${IMG_SIZE} -le 0 ]; then
    # calc image size
    IMG_SIZE=$(((`du -s -B64M ${ROOTFS_DIR} | cut -f1` + 3) * 1024 * 1024 * 64))
    IMG_BLK=$((${IMG_SIZE} / 4096))
    INODE_SIZE=$((`find ${ROOTFS_DIR} | wc -l` + 128))
    # make fs
    [ -f ${IMG_FILE} ] && rm -f ${IMG_FILE}
    ${MKFS} -N ${INODE_SIZE} ${MKFS_OPTS} -d ${ROOTFS_DIR} ${IMG_FILE} ${IMG_BLK}
else
    IMG_BLK=$((${IMG_SIZE} / 4096))
    INODE_SIZE=$((`find ${ROOTFS_DIR} | wc -l` + 128))
    [ -f ${IMG_FILE} ] && rm -f ${IMG_FILE}
    ${MKFS} -N ${INODE_SIZE} ${MKFS_OPTS} -d ${ROOTFS_DIR} ${IMG_FILE} ${IMG_BLK}
fi
if [ ${TARGET_OS} != "eflasher" ]; then
    ${TOP}/tools/generate-partmap-txt.sh ${IMG_SIZE} ${TARGET_OS}
fi

echo "generating ${IMG_FILE} done."
echo 0
