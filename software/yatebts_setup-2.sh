#Important: requires sudo permissions
#Install necessary packages for bladerf operation
add-apt-repository ppa:bladerf/bladerf
apt-get update
apt-get -y install bladerf
apt-get -y install libbladerf-dev

apt-get -y install bladerf-firmware-fx3
apt-get -y install bladerf-fpga-hostedx40   # for the 40 kLE hardware
apt-get -y install bladerf-fpga-hostedx115  #for the 115 kLE hardware

#Flash firmware (first time only)
bladeRF-cli --flash-firmware /usr/share/Nuand/bladeRF/bladeRF_fw.img

#Probe for device
blade-cli -p
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
usermod -a -G yate ubuntu #CHANGE ubuntu to the user currently doing everything

#Fetch Yate and Yate-BTS
mkdir ~/software
cd ~/software
mkdir null
cd null
#Only checkout specific versions of yate and yatebts
svn checkout -r6315 http://yate.null.ro/svn/yate/trunk yate
svn checkout -r660 http://voip.null.ro/svn/yatebts/trunk yatebts

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

#Change path in [transceiver] section in ybts.conf to ./transceiver-bladerf
#Details: https://wiki.yatebts.com/index.php/Running

#Start yate in the background
#yate -sd -vvvvv -l /var/log/yate.log
#To stop yate:

#Copy configuration files and modified scripts

#Firewall configuration for GPRS

#Wondershaper configuration
apt-get -y install wondershaper

#Python configuration
apt-get -y install python
apt-get -y install python-pip
