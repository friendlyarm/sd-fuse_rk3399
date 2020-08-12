#!/bin/bash
set -eu

[ -f ${PWD}/mk-emmc-image.sh ] || {
	echo "Error: please run at the script's home dir"
	exit 1
}

cp -f $2/boot.img $1/
cp -f $2/idbloader.img $1/
cp -f $2/misc.img $1/

# TODO: env.conf?

if [ ! -f $1/userdata.img ]; then
	USERDATA_SIZE=104857600
	echo "Generating empty userdata.img (size:${USERDATA_SIZE})"
	TMPDIR=`mktemp -d`
	${PWD}/tools/make_ext4fs -s -l ${USERDATA_SIZE} -a root -L userdata $1/userdata.img ${TMPDIR}
	rm -rf ${TMPDIR}
fi

exit $?
