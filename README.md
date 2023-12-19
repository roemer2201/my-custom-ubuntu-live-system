# My custom Ubuntu live system
Aim of this project is to build a fully remote accessible Ubuntu live system, that commes with various tools preinstalled for fixing, cloning and testing computers

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
apt install pv vim dislocker net-tools nfs-common sysstat iotop nvme-cli open-vm-tools

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
smbpasswd -a -n ubuntu

# Install wsdd2 to make the live system show up via neighbor discovery
apt install wsdd2
systemctl enable wsdd2.service

# Install and configure openssh-server to make the live system accessible through ssh
apt install openssh-server
systemctl enable sshd.service
vim /etc/ssh/sshd_config

# in case this image is booted inside a virtual machine
apt install open-vm-tools
systemctl status open-vm-tools.service
systemctl enable open-vm-tools.service

# create a systemd service file to execute custom scripts
vim /etc/systemd/system/ubuntu-live-custom.service
# create the custom script
vim /etc/ubuntu-live-custom.sh
chmod +x /etc/ubuntu-live-custom.sh

# Enable Ubuntu's remote desktop feature and configure it
# !! This section was copied from history and needs rework and explanations !!
export GRDCERTDIR=/etc/skel/.cert
mkdir -p ${GRDCERTDIR}
openssl genrsa -out ${GRDCERTDIR}/grd-tls.key 4096
openssl req -new -key ${GRDCERTDIR}/grd-tls.key -out ${GRDCERTDIR}/grd-tls.csr -subj "/C=DE/ST=Private/L=Home/O=Family/OU=IT Department/CN=ubuntu-live"
openssl x509 -req -days 100000 -signkey ${GRDCERTDIR}/grd-tls.key -in ${GRDCERTDIR}/grd-tls.csr -out ${GRDCERTDIR}/grd-tls.crt
cd /etc/skel
mkdir -m 700 -p .local/bin
vim .local/bin/configure-grd.sh
cat  /usr/lib/systemd/user/configure-grd.service
ll .config/systemd/user/gnome-session.target.wants/
mkdir -p /etc/skel/.local/share/keyrings
cd /etc/skel/.local/share/keyrings
chmod -R og-rwx .
chmod -x Default_keyring.keyring default 
chmod go+r Default_keyring.keyring default 
chmod g+w Default_keyring.keyring default 
chmod 600 Default_keyring.keyring 
vim /etc/skel/.local/bin/configure-grd.sh
cd
ll
mkdir -m 700 /etc/skel/.local/share/gnome-shell
mkdir -m 775 /etc/skel/.local/share/gnome-shell/extentions
cd /etc/skel/.local/share/gnome-shell/extentions
unzip /root/allowlockedremotedesktopkamens.us.v9.shell-extension.zip 
mkdir allowlockedremotedesktop@kamens.us
mv * allowlockedremotedesktop@kamens.us/
ll allowlockedremotedesktop@kamens.us/
vim /etc/skel/.local/bin/configure-grd.sh
cd /etc/skel/.local/share/gnome-shell/extentions
gnome-extensions install --help
gnome-extensions install allowlockedremotedesktopkamens.us.v9.shell-extension.zip 
gnome-extensions list
find /usr/ -name \*allowlockedremotedesktop\*
glib-compile-schemas --help
mv ~/.local/share/gnome-shell/extensions/allowlockedremotedesktop@kamens.us /usr/share/gnome-shell/extensions/
cd /etc/skel/.local/share/gnome-shell/extensions/
cd .local/share/gnome-shell/extensions/
cd /etc/skel/.local/share/gnome-shell/extensions/
cd /etc/skel/.local/share/gnome-shell/
ll
mv extentions/ extensions/
vim /etc/dconf/profile/user
mkdir -p /etc/dconf/db/local.d/
touch /etc/dconf/db/local.d/00-extensions
gnome-extensions list
vim /etc/dconf/db/local.d/00-extensions
dconf update
```
