#!/bin/bash
#samba
#set static ip address
#move configs into ~/ etc/skel, and /root

if [ "$EUID" -ne 0 ]
  then echo "This program must be run as a priviledged user"
  exit
fi

RM="nano"

ESS_PROGS="vim \
htop\
pv \
rhash \
gdebi \
screen \
dcfldd \
secure-delete"

NET_PROGS="git \
curl \
iptables \
ufw \
tcpdump \
resolvconf \
openssh-server \
nmap \
netcat \
nfs-common \
cryptcat"

DESKTOP_PROGS="conky \
gparted\
vlc \
gufw \
wine \
filezilla \
mysql-workbench \
zenmap \
wireshark"

SERVER_PROGS="apache2 \
mysql-server \
fail2ban \
php5 \
php5-cli \
php5-curl \
php5-gd \
php5-imagick \
php5-json \
php5-mysql \
php5-sasl \
php5-sqlite \
php5-xsl"

apt-get -y install $PROGS
apt-get -y purge $RM
apt-get update && apt-get upgrade
apt-get dist-upgrade

echo "blacklist floppy" | tee /etc/modprobe.d/blacklist-floppy.conf
rmmod floppy
update-initramfs -u
