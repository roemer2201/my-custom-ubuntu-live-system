#!/bin/bash
# configure hostname
HOSTIP=$(hostname -I | awk '{print $1}' | sed 's/\./-/g')
if [ -z "$HOSTIP" ]; then
	# Fallback: product_uuid (ersten 8 Zeichen)
	if [[ -r /sys/class/dmi/id/product_uuid ]]; then
		HOSTID=$(cut -c1-8 /sys/class/dmi/id/product_uuid)
	else
		HOSTID="no-uuid"
	fi
	hostnamectl set-hostname "ucl-$HOSTID"
else
	hostnamectl hostname "ucl-$HOSTIP"
fi
# restart samba to use the new hostname
systemctl restart smbd
# create RAM-disk for convenient temporary storage
RAMDISKDIR=/ram
mkdir $RAMDISKDIR
chmod +t $RAMDISKDIR
mount -t tmpfs -o size=80% tmpfs $RAMDISKDIR
