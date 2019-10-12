#!/bin/bash
set -eu

[ -f ${PWD}/mk-emmc-image.sh ] || {
	echo "Error: please run at the script's home dir"
	exit 1
}

true ${SOC:=rk3399}
ROOTFS_DIR=$1

MODULES_DIR=./lib/modules/4.4.179
(cd $ROOTFS_DIR && {
    for f in `find ${MODULES_DIR} -name *.ko`; do
        ko=${MODULES_DIR}/`basename ${f}`
        if [ ! -e "${ko}" ] ; then
            mv ${f} ${MODULES_DIR}/
        fi
    done
})

exit 0
