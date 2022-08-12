#!/bin/bash
set -eu

[ -f ${PWD}/mk-emmc-image.sh ] || {
	echo "Error: please run at the script's home dir"
	exit 1
}

ROOTFS_DIR=$1

(cd ${ROOTFS_DIR}/lib/modules/ && {
    for MODULES_DIR in `ls .`
    do
        for f in `find ${MODULES_DIR} -name *.ko`; do
            ko=${MODULES_DIR}/`basename ${f}`
            if [ ! -e "${ko}" ] ; then
                mv ${f} ${MODULES_DIR}/
            fi
        done
        depmod -a -b ${ROOTFS_DIR} `basename ${MODULES_DIR}`
        (cd ${MODULES_DIR} && {
            rm -rf ./build ./source
            find . -mindepth 1 -type d -print0 | xargs -0 rm -rf
        })
    done
})

exit 0
