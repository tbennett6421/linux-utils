#!/bin/bash

if [ "$EUID" -ne 0 ]; then 
	echo "This program must be run as a privileged user"
  	exit 1
fi

echo -n "Enter the new hostname and press [ENTER]: "
read h_name
echo ""

# Change hostname
echo "Setting hostname to \"$h_name\""
echo "# hostname $h_name"
echo "# echo $h_name > /etc/hostname"
echo "# sed -ie 's/ubuntu/$h_name/g' /etc/hosts"
hostname $h_name
echo $h_name > /etc/hostname
sed -ie 's/ubuntu/$h_name/g' /etc/hosts


# Generate new ssh host keys
echo "Generating new ssh keys"
echo "-- removing old keys"
echo "-- # rm -v /etc/ssh/ssh_host_*"
echo "-- generating new keys"
echo "-- # dpkg-reconfigure openssh-server"
rm -v /etc/ssh/ssh_host_*
dpkg-reconfigure openssh-server









