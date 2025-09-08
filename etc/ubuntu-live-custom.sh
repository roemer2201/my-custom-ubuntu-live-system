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
	NEWHOSTNAME="ucl-$HOSTID"
	hostnamectl set-hostname "$NEWHOSTNAME"
else
	NEWHOSTNAME="ucl-$HOSTIP"
	hostnamectl hostname "$NEWHOSTNAME"
fi
[ -f /etc/hosts ] && sed -i -E "s/^(127\.0\.1\.1[[:space:]]+).*/\1$NEWHOSTNAME/" /etc/hosts
# restart samba to use the new hostname
systemctl restart smbd
# create RAM-disk for convenient temporary storage
RAMDISKDIR=/ram
mkdir $RAMDISKDIR
chmod +t $RAMDISKDIR
mount -t tmpfs -o size=80% tmpfs $RAMDISKDIR
