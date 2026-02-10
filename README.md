# My custom Ubuntu live system
Aim of this project is to build a fully remote accessible Ubuntu live system, that commes with various tools preinstalled for fixing, cloning and testing computers

# Key features when booted
- remote access via SSH, Samba, Gnome Remote Desktop (GRD)
- custom packages installed
- unique hostname based on network IP or product_uuid, e.g. "ucl-192.168.1.123" in case of IP "192.168.1.123" or "ucl-abcd1234"
- changed to my countries common keyboard layout as default

# Prerequisites
- Ubuntu 22.04 maschine for generating the image
- cubic installed on that system (https://github.com/PJ-Singh-001/Cubic)
- an Ubuntu ISO file (http://ubuntu.mirror.tudos.de/ubuntu-releases/22.04/)

# Creation steps
- launch cubic and select a working directory, click next
- select the ISO file, maybe modify other options, click next
- make changes to the virtual environment
```bash
# make universe repo available
apt-add-repository universe
apt update

# install all desired tools
# common tools
apt install vim git open-vm-tools screen xxhash minicom autossh
# performance tools
apt install pv sysstat iotop htop bashtop 
# network tools
apt install ethtool tcptrack nmon nethogs bmon slurm netperf socat ipmitool wireshark
# disk-tools
apt install dislocker net-tools nfs-common nvme-cli smartmontools     
# add external repositories with needed tools
apt-add-repository ppa:tomtomtom/woeusb
apt install woeusb-frontend-wxgtk woeusb

# fix the Ubuntu 22.04 live bug, where network access with dhcp does not work out of the box
# this is a hardcoded fix, I did not investigate deeper to make a propper change
vi /etc/systemd/resolved.conf
vi /etc/systemd/timesyncd.conf

# set "de_DE.UTF-8" as default locale
update-locale LANG=de_DE.UTF-8
update-locale LC_MESSAGES=de_DE.UTF-8
update-locale LC_ALL=de_DE.UTF-8

# Install an configure Samba to copy files from or to the live system
apt install samba
vim /etc/samba/smb.conf
systemctl enable smbd.service
systemctl start smbd.service
smbpasswd -a -n ubuntu        # use a simple password like "ubuntu"

# Install wsdd2 to make the live system show up via neighbor discovery
apt install wsdd2
systemctl enable wsdd2.service

# Install and configure openssh-server to make the live system accessible through ssh
apt install openssh-server
systemctl enable sshd.service
# the ubuntu user account does not have a password, therefore set
# "PermitEmptyPasswords yes" in:
vim /etc/ssh/sshd_config

# in case this image gets booted inside a virtual machine
apt install open-vm-tools
systemctl status open-vm-tools.service
systemctl enable open-vm-tools.service

# create a systemd service file to execute custom scripts
vim /etc/systemd/system/ubuntu-live-custom.service
# create the custom script
vim /etc/ubuntu-live-custom.sh
chmod +x /etc/ubuntu-live-custom.sh

# Enable Ubuntu's Gnome remote desktop (GRD) feature and configure it
# !! This section was copied from history and needs rework and explanations !!
# Enroll self-signed certificate for RDP's encryption
export GRDCERTDIR=/etc/skel/.cert
mkdir -p ${GRDCERTDIR}
openssl genrsa -out ${GRDCERTDIR}/grd-tls.key 4096
openssl req -new -key ${GRDCERTDIR}/grd-tls.key -out ${GRDCERTDIR}/grd-tls.csr -subj "/C=DE/ST=Private/L=Home/O=Family/OU=IT Department/CN=ubuntu-live"
openssl x509 -req -days 100000 -signkey ${GRDCERTDIR}/grd-tls.key -in ${GRDCERTDIR}/grd-tls.csr -out ${GRDCERTDIR}/grd-tls.crt
# create a configuration script for which will be run at everytime the live system is booted
cd /etc/skel
mkdir -m 700 -p .local/bin
vim .local/bin/configure-grd.sh
# make this script run as systemd user service
cat  /usr/lib/systemd/user/configure-grd.service
cd .config/systemd/user/gnome-session.target.wants/
ln -sf /usr/lib/systemd/user/configure-grd.service
ln -sf /usr/lib/systemd/user/configure-gnome.service
# create keyring files, which store the credentials that allow access to GRD
mkdir -p /etc/skel/.local/share/keyrings
cd /etc/skel/.local/share/keyrings
chmod -R og-rwx .
chmod -x Default_keyring.keyring default 
chmod go+r Default_keyring.keyring default 
chmod g+w Default_keyring.keyring default 
chmod 600 Default_keyring.keyring
# GRD does not allow connections to locked screens, as a workaround we can install an extension:
mkdir -m 700 /etc/skel/.local/share/gnome-shell
mkdir -m 775 /etc/skel/.local/share/gnome-shell/extentions
cd /etc/skel/.local/share/gnome-shell/extentions
# download the extension
unzip /root/allowlockedremotedesktopkamens.us.v9.shell-extension.zip 
mkdir allowlockedremotedesktop@kamens.us
mv * allowlockedremotedesktop@kamens.us/
ll allowlockedremotedesktop@kamens.us/
cd /etc/skel/.local/share/gnome-shell/extentions
gnome-extensions install allowlockedremotedesktopkamens.us.v9.shell-extension.zip 
gnome-extensions list
find /usr/ -name \*allowlockedremotedesktop\*
mv ~/.local/share/gnome-shell/extensions/allowlockedremotedesktop@kamens.us /usr/share/gnome-shell/extensions/
cd /etc/skel/.local/share/gnome-shell/extensions/
cd /etc/skel/.local/share/gnome-shell/extensions/
cd /etc/skel/.local/share/gnome-shell/
mv extentions/ extensions/
# I do not remember, why these steps are nescessary
vim /etc/dconf/profile/user
mkdir -p /etc/dconf/db/local.d/
touch /etc/dconf/db/local.d/00-extensions
gnome-extensions list
vim /etc/dconf/db/local.d/00-extensions
dconf update
# Added tor to the live system
apt install apt-transport-https
cd /tmp/
wget https://deb.torproject.org/torproject.org/pool/main/d/deb.torproject.org-keyring/deb.torproject.org-keyring_2022.04.27.1_all.deb
apt install ./deb.torproject.org-keyring_2022.04.27.1_all.deb
sh -c 'echo "deb [arch=amd64 signed-by=/usr/share/keyrings/deb.torproject.org-keyring.gpg] https://deb.torproject.org/torproject.org $(lsb_release -sc) main" >> /etc/apt/sources.list.d/tor-project.list'
apt update
apt install tor
systemctl disable tor # Disable it by default, so only launch when needed
wget https://dist.torproject.org/torbrowser/13.0.14/tor-browser-linux-x86_64-13.0.14.tar.xz
cd /opt/
tar xf /tmp/tor-browser-linux-x86_64-13.0.14.tar.xz 
```
- when finished modifying the image using the root shell, click next
- manually select/deselect packages, click next
- select a kernel (most likely the highest one)
- click "boot" in the top middle of the cubic window to make changes to the grub boot loader of the live cd (do not show Ubiquity install dialogue, set default keyboard layout
  - grub.cfg (only modified entries displayed)
```
menuentry "Try Ubuntu custom without installing (DE)" {
	set gfxpayload=keep
	linux	/casper/vmlinuz boot=casper file=/cdrom/preseed/ubuntu.seed quiet splash debian-installer/locale=de_DE.UTF-8 console-setup/layoutcode=de keyboard-configuration/layoutcode=de keyboard-configuration/variant=German --- 
	initrd	/casper/initrd.gz
}
menuentry "Try Ubuntu custom without installing" {
	set gfxpayload=keep
	linux	/casper/vmlinuz boot=casper file=/cdrom/preseed/ubuntu.seed quiet splash --- 
	initrd	/casper/initrd.gz
}
menuentry "Try Ubuntu custom without installing (safe graphics)" {
	set gfxpayload=keep
	linux	/casper/vmlinuz boot=casper nomodeset file=/cdrom/preseed/ubuntu.seed quiet splash --- 
	initrd	/casper/initrd.gz
}
```
  - loopback.cfg (only modified entries displayed)
```
menuentry "Try Ubuntu custom without installing (DE)" {
	set gfxpayload=keep
	linux	/casper/vmlinuz boot=casper file=/cdrom/preseed/ubuntu.seed iso-scan/filename=${iso_path} quiet splash debian-installer/locale=de_DE.UTF-8 console-setup/layoutcode=de keyboard-configuration/layoutcode=de keyboard-configuration/variant=German --- 
	initrd	/casper/initrd.gz
}
menuentry "Try Ubuntu custom without installing" {
	set gfxpayload=keep
	linux	/casper/vmlinuz boot=casper file=/cdrom/preseed/ubuntu.seed iso-scan/filename=${iso_path} quiet splash --- 
	initrd	/casper/initrd.gz
}
menuentry "Try Ubuntu custom without installing (safe graphics)" {
	set gfxpayload=keep
	linux	/casper/vmlinuz boot=casper nomodeset file=/cdrom/preseed/ubuntu.seed iso-scan/filename=${iso_path} quiet splash --- 
	initrd	/casper/initrd.gz
}
```
- click next
- choose a compression method, click next
- let cubic do it's work, click finish


# ToDo -> Implementation
- launch netserver automatically
