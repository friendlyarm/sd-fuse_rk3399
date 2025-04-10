#!/bin/bash
set -eu
ROOTFS_DIR=$1
CURRPATH=$PWD

if [ -e "$ROOTFS_DIR/lib/firmware" ]; then
	LIBFIRMWARE="$(readlink -f $ROOTFS_DIR/lib/firmware)"
elif [ -e "$ROOTFS_DIR/usr/lib/firmware" ]; then
	LIBFIRMWARE="$(readlink -f $ROOTFS_DIR/usr/lib/firmware)"
else
	LIBFIRMWARE="$ROOTFS_DIR/lib/firmware"
	mkdir -p $LIBFIRMWARE
fi

(cd $ROOTFS_DIR && {
	# apply etc/firmware
	[ -L etc/firmware ] && rm -f etc/firmware
	cp -af $CURRPATH/files/etc/* etc/

	# apply system/etc system/vendor
	[ -d system ] || mkdir system
	cp -af $CURRPATH/files/system/* system/

	# apply /usr/lib/firmware or /lib/firmware
	cp -af $CURRPATH/files/usr/lib/firmware/* "${LIBFIRMWARE}/"

	# apply regulatory.db and regulatory.db.p7s
	if [ ! -f "${LIBFIRMWARE}/regulatory.db" -a ! -L "${LIBFIRMWARE}/regulatory.db" ]; then
		cp -f $CURRPATH/files2/usr/lib/firmware/regulatory.db "${LIBFIRMWARE}/"
		cp -f $CURRPATH/files2/usr/lib/firmware/regulatory.db.p7s "${LIBFIRMWARE}/"
	fi
	if [ ! -f "${LIBFIRMWARE}/regulatory.db.p7s" -a ! -L "${LIBFIRMWARE}/regulatory.db.p7s" ]; then
		cp -f $CURRPATH/files2/usr/lib/firmware/regulatory.db "${LIBFIRMWARE}/"
		cp -f $CURRPATH/files2/usr/lib/firmware/regulatory.db.p7s "${LIBFIRMWARE}/"
	fi
})
