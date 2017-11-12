#!/bin/bash
# Portable Cell Initiative
# Script for setting up the OpenBTS environment with SDR
# Version 1.0

#Instructions:
#Place setup.sh in folder called /scripts
#export PATH="$PATH:~/scripts"
#chmod u+x setup.sh
#If the script is not in the PATH, run it with sudo ./setup.sh
#WARNING: must be run with sudo

#Set the current user (so the correct directory to NodeManager may be established)
#TO-DO: Update this so it is automatically detected upon completely of the main setup script, or have it typed in manually by the user
USER=akovesdy

clear
echo "PCI Setup Script Starting"

#TODO add-apt commands
apt-get update
apt-get install -y subversion
echo "Subversion installed"
apt-get install -y vim
echo "Vim installed"
apt-get install -y git
echo "Git installed"

echo "Bladerf library installation starting"

#For Ubuntu 14.04 or later
apt-get install -y software-properties-common python-software-properties
add-apt-repository -y ppa:bladerf/bladerf
apt-get update
apt-get install -y bladerf

apt-get install -y libbladerf-dev

apt-get install -y bladerf-firmware-fx3
apt-get install -y bladerf-fpga-hostedx40

echo "Bladerf library installation complete"

echo "Installing other dependencies"
apt-get install -y $(
    wget -qO - https://raw.githubusercontent.com/RangeNetworks/dev/master/build.sh | \
    grep installIfMissing | \
    grep -v "{" | \
    cut -f2 -d" ")

apt-get update
apt-get install -y autoconf automake libtool debhelper sqlite3 libsqlite3-dev libusb-1.0-0 \
    libusb-1.0-0-dev libortp-dev libosip2-dev libreadline-dev libncurses5 libncurses5-dev \
    pkg-config cdbs libsqlite0-dev unixodbc unixodbc-dev libssl-dev libsrtp0 libsrtp0-dev \
    libsqliteodbc python-zmq dpkg-dev
add-apt-repository -y ppa:chris-lea/zeromq
apt-get update
apt-get install -y libzmq3-dbg libzmq3-dev libzmq3 python-zmq
#Libort8 installation requires reference to Ubuntu 12:
sed -i "$ a deb http://us.archive.ubuntu.com/ubuntu precise main universe" /etc/apt/sources.list
apt-get update;
apt-get install libortp8 libosip2-4

#Build UHD from source
apt-get install -y gnuradio
apt-get install -y libuhd-dev libuhd003 uhd-host

#Install OpenBTS
DIRECTORY=openbts
cd /home
if [ ! -d $DIRECTORY ]; then
	mkdir /home/$DIRECTORY
fi
cd /home/$DIRECTORY

git clone https://github.com/RangeNetworks/openbts.git;
git clone https://github.com/RangeNetworks/smqueue.git;
git clone https://github.com/RangeNetworks/subscriberRegistry.git;

for D in *; do (
    echo $D;
    echo "=======";
    cd $D;
    git clone https://github.com/RangeNetworks/CommonLibs.git;
    git clone https://github.com/RangeNetworks/NodeManager.git);
done;
git clone https://github.com/RangeNetworks/libcoredumper.git
git clone https://github.com/RangeNetworks/liba53.git

#Build libcoredumper
cd libcoredumper;
./build.sh && \
   dpkg -i *.deb;
cd ..

#Build liba53
cd liba53;
make && \
   make install;
cd ..;

#Copy the YateBTS code from subversion
svn checkout --revision 503 http://voip.null.ro/svn/yatebts/trunk yatebts
vim ./yatebts/mbts/TransceiverRAD1/bladeRFDevice.cpp "+112s/^/#ifdef NEVER" +133s/^/#endif +wq
clear
cd yatebts
./autogen.sh
vim configure +4263,4291s/^/#/ +wq
clear
./configure

#Build the two directories required in YateBTS
cd /home/openbts/yatebts/mbts/Peering
make
cd /home/openbts/yatebts/mbts/TransceiverRAD1
vim Makefile "+26s/$/ -lpthread/" +wq
make
echo "YateBTS cloned"

#Copy YateBTS files over to OpenBTS
cd /home/$DIRECTORY
cp ./yatebts/mbts/TransceiverRAD1/transceiver-bladerf openbts/apps/
cd openbts/apps/
ln -sf transceiver-bladerf transceiver

#Build OpenBTS
echo "OpenBTS Build Starting"
cd /home/$DIRECTORY/openbts
./autogen.sh
./configure --with-uhd
#Potential error occured here
make

#Configure certain variables for bladeRF operation:
GSMBand=900
RadioC0=51
ARFCNs=1
MCC=001
MNC=01
ShortName=Disaster Relief Cellular
RegistrationNumber=101
IMSIAllowed=^001

cd apps
sed -i "s/GSM.Radio.RxGain','47'/GSM.Radio.RxGain','5'/g" OpenBTS.example.sql
sed -i "s/GSM.Radio.PowerManager.MaxAttenDB','10'/GSM.Radio.PowerManager.MaxAttenDB','35'/g" OpenBTS.example.sql
sed -i "s/GSM.Radio.PowerManager.MinAttenDB','0'/GSM.Radio.PowerManager.MinAttenDB','35'/g" OpenBTS.example.sql

#Configure band and network
sed -i "s/GSM.Radio.Band','900'/GSM.Radio.Band','$GSMBAND'/g" OpenBTS.example.sql
sed -i "s/GSM.Radio.C0','51'/GSM.Radio.Band','$RadioC0'/g" OpenBTS.example.sql
sed -i "s/GSM.Radio.ARFCNs','1'/GSM.Radio.Band','$ARFCNs'/g" OpenBTS.example.sql
#MCC and MNC
sed -i "s/GSM.Identity.MCC','001'/GSM.Identity.MCC','$MCC'/g" OpenBTS.example.sql
sed -i "s/GSM.Identity.MNC','01'/GSM.Identity.MNC','$MNC'/g" OpenBTS.example.sql
sed -i "s/GSM.Identity.ShortName','Range'/GSM.Identity.ShortName','$ShortName'/g" OpenBTS.example.sql

#Instruct nonsubscriber phones to not pester the network constantly with reconnections
sed -i "s/Control.LUR.404RejectCause','0x04'/Control.LUR.404RejectCause','0x0C'/g" OpenBTS.example.sql
sed -i "s/Control.LUR.UnprovisionedRejectCause','0x0C'/Control.LUR.UnprovisionedRejectCause','0x0C'/g" OpenBTS.example.sql

#GPRS control
sed -i "s/GPRS.Enable','0'/GPRS.Enable','1'/g" OpenBTS.example.sql

#OpenRegistration configuration
#Regex expression for controlling who gets to open register (.* matches all IMSIs)
sed -i "s/Control.LUR.OpenRegistration',''/Control.LUR.OpenRegistration','$IMSIAllowed'/g" OpenBTS.example.sql
sed -i "s/Control.LUR.OpenRegistration.Message','Welcome to the test network. Your IMSI is '/Control.LUR.OpenRegistration','Connected to Disaster Relief Cellular. Your IMSI is '/g" OpenBTS.example.sql
sed -i "s/Control.LUR.OpenRegistration.Reject',''/Control.LUR.OpenRegistration.Reject',''/g" OpenBTS.example.sql
sed -i "s/Control.LUR.OpenRegistration.ShortCode','101'/Control.LUR.OpenRegistration.ShortCode','$RegistrationNumber'/g" OpenBTS.example.sql

#Turn on "Emergency Calls not supported beacon" for testing purposes
sed -i "s/GSM.RACH.AC','0x0400'/GSM.RACH.AC','0x0400'/g" OpenBTS.example.sql
#Uncomment following line for full access with no restrictions (DANGER)
#sed -i "s/GSM.RACH.AC','0x0400'/GSM.RACH.AC','0'/g" OpenBTS.example.sql

#Enable PhysicalStatus API
sed -i "s/NodeManager.API.PhysicalStatus','disabled'/NodeManager.API.PhysicalStatus','0.1'/g" OpenBTS.example.sql

#Configure OpenBTS and upload database
mkdir /etc/OpenBTS
cd /etc/OpenBTS
sqlite3 -init ./apps/OpenBTS.example.sql /etc/OpenBTS/OpenBTS.db ".quit"
#TEST with (see a bunch of configuration variables)
#sqlite3 /etc/OpenBTS/OpenBTS.db .dump

#Create subscriber registry
mkdir -p /var/lib/asterisk/sqlite3dir
#Build sipauthserve
cd /home/$DIRECTORY/subscriberRegistry
./autogen.sh
./configure
make
#Potential error -> might be in subscriberRegistry instead of /openbts/apps
cd /home/$DIRECTORY/openbts/apps
sqlite3 -init subscriberRegistry.example.sql /etc/OpenBTS/sipauthserve.db ".quit"

#Install SMQueue
cd /home/$DIRECTORY/smqueue
cp ../subscriberRegistry/{SubscriberRegistry.cpp,SubscriberRegistry.h} smqueue/;
cp ../subscriberRegistry/SubscriberRegistry.cpp SR/
autoreconf -i;
./configure;
make
sqlite3 -init smqueue/smqueue.example.sql /etc/OpenBTS/smqueue.db ".quit"

#Create logs if they do not already exist
mkdir -p /var/lib/OpenBTS;
touch /var/lib/OpenBTS/smq.cdr

#Make sure screen is installed (should be by default)
apt-get install -y screen

#Configure firewall (for allowing GPRS connections)
#Substitute custom set of rules here if you want
IPRulesLocation=/home/$DIRECTORY/openbts/apps/iptables.rules
iptables-restore < $IPRulesLocation
#Permamently change the etc/network/interfaces file to apply changes whenever the eth0 interface is opened
sed -i "$ a \\\tpre-up iptables-restore < $IPRulesLocation" /etc/network/interfaces

echo "Primary Configuration complete"
echo "Starting Secondary configuration on OpenBTS, SMQueue, and other services"

#Start all services
cd /home/$DIRECTORY/smqueue/smqueue/; ./smqueue &
cd /home/$DIRECTORY/subscriberRegistry/apps/; ./sipauthserve &
cd /home/$DIRECTORY/openbts/apps
screen -S openbtsCLI ./OpenBTS

#Set variables through nmcli.py
cd /home/$USER/NodeManager/
#Changes the code for SMqueue to accept OpenRegistration applications through the number #101
./nmcli.py smqueue config update SC.Register.Code $RegistrationNumber

echo "Secondary Configuration complete"
echo "Execute start.sh to startup OpenBTS"

#Optional
echo "Starting OpenBTS"
./start.sh