#!/bin/bash
# Extract last octet of IP and append it to the hostname
hostnamectl hostname ubuntu-live-ip-$(hostname -I | awk 'BEGIN { FS="[. ]" } ; {print substr($4,0)}')
systemctl restart smbd
RAMDISKDIR=/ram
mkdir $RAMDISKDIR
chmod +t $RAMDISKDIR
mount -t tmpfs -o size=80% tmpfs $RAMDISKDIR
