#!/bin/bash
#Important: requires sudo permissions
#Install necessary packages for bladerf operation
add-apt-repository ppa:bladerf/bladerf
apt-get update
apt-get -y install bladerf
apt-get -y install libbladerf-dev

apt-get -y install bladerf-firmware-fx3
#apt-get -y install bladerf-fpga-hostedx40   # for the 40 kLE hardware
apt-get -y install bladerf-fpga-hostedx115  #for the 115 kLE hardware

#Flash firmware (first time only)
bladeRF-cli --flash-firmware /usr/share/Nuand/bladeRF/bladeRF_fw.img

#Probe for device
bladeRF-cli -p
#blade-cli -i #Enter interactive mode

#Manually load the FPGA image
#Load the image you need (either x40 or x115)
#bladeRF-cli -l /usr/share/Nuand/bladeRF/hostedx40.rbf
bladeRF-cli -l /usr/share/Nuand/bladeRF/hostedx115.rbf

#https://github.com/Nuand/bladeRF/wiki/Setting-up-Yate-and-YateBTS-with-the-bladeRF
#Install yate and yatebts
apt-get install -y subversion build-essential automake autoconf libusb-1.0-0-dev libgsm1-dev gcc

#Create custom user group to manage everything
addgroup yate
usermod -a -G yate odroid #CHANGE ubuntu to the user currently doing everything

#Fetch Yate and Yate-BTS
mkdir ~/software
cd ~/software
mkdir null
cd null
#Only checkout specific versions of yate and yatebts
svn checkout -r6315 http://yate.null.ro/svn/yate/trunk yate
svn checkout -r660 http://voip.null.ro/svn/yatebts/trunk yatebts
#Allow ownership for all users
chown -R odroid yatebts
chown -R odroid yate

#Building and installing yate/yatebts
cd ~/software/null/yate
./autogen.sh
./configure --prefix=/usr/local
make
#If there are no issues, continue:
make install
ldconfig

cd ~/software/null/yatebts
./autogen.sh
./configure --prefix=/usr/local
make
make install
ldconfig

#Configuration
#Allow yate group to modify config files, etc
touch /usr/local/etc/yate/snmp_data.conf /usr/local/etc/yate/tmsidata.conf
chown root:yate /usr/local/etc/yate/*.conf
chmod g+w /usr/local/etc/yate/*.conf

#Copy configuration files and modified scripts
cd ~/code/portable-cell-initiative/software/customYBTS
rm -rf /usr/local/etc/yate/*
cp -a config/*  /usr/local/etc/yate
rm -rf /usr/local/share/yate/scripts/*
cp -a scripts/* /usr/local/share/yate/scripts

#Firewall configuration for GPRS
iptables -A POSTROUTING -t nat -s 192.168.99.0/24 ! -d 192.168.99.0/24 -j MASQUERADE

#To save iptables
apt-get install -y iptables-persistent
iptables-save > /etc/iptables/rules.v4
iptables-save > /etc/iptables/rules.v6

#Enable IP Forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward
sed -i "s/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g" /etc/sysctl.conf

#Apache, PHP, webgui installation and configuration
apt-get install apache2 -y
apt-get install -y php libapache2-mod-php php-mysql
ufw enable
ufw allow in "Apache Full" #Configure the apache server

cd /var/www/html
ln -s /usr/local/share/yate/nipc_web nipc #Copy over webGUI file to apache
chmod -R a+rw /usr/local/etc/yate/ #Give the user permission to write to the configuration files
systemctl restart apache2 #Start or restart the apache server
#verify that the server is listening on port 80 in ports.conf

#To find public IP address
hostname -I
#To access the webgui, visit http://127.0.0.1/nipc (local address)

#Wondershaper configuration
apt-get -y install wondershaper

#Python configuration
apt-get -y install python
apt-get -y install python-pip

#Enable monitoring via screen by moving python file
cd ~/code/portable-cell-initiative/software
cp pci_serial.py /bin
(sudo crontab -l; echo "@reboot python /bin/pci_serial.py &") | sudo crontab -
(sudo crontab -l; echo "@reboot yate -s -d") | sudo crontab -

#Reboot to update firmware on bladeRF and start yate
reboot
