#!/bin/bash
export GRDCERTDIR=~/.cert
grdctl rdp enable
#grdctl rdp set-credentials ubuntu ""
grdctl rdp disable-view-only
grdctl rdp set-tls-cert ${GRDCERTDIR}/grd-tls.crt
grdctl rdp set-tls-key ${GRDCERTDIR}/grd-tls.key
systemctl --user enable gnome-remote-desktop.service
systemctl --user restart gnome-remote-desktop.service
gnome-extension enable allowlockedremotedesktop@kamens.us
