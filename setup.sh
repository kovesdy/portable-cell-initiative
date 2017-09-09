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
apt-get install -y libzmq3-dbg libzmq3-dev libzmq3
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

#Configure certain variables for bladeRF operation
cd apps
sed -i "s/GSM.Radio.RxGain','47'/GSM.Radio.RxGain','5'/g" OpenBTS.example.sql
sed -i "s/GSM.Radio.PowerManager.MaxAttenDB','10'/GSM.Radio.PowerManager.MaxAttenDB','35'/g" OpenBTS.example.sql
sed -i "s/GSM.Radio.PowerManager.MinAttenDB','0'/GSM.Radio.PowerManager.MinAttenDB','35'/g" OpenBTS.example.sql

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

echo "Configuration complete"
echo "Execute start.sh to startup OpenBTS"

#Optional
echo "Starting OpenBTS"
./start.sh