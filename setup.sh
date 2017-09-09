#!/bin/bash
# Portable Cell Initiative
# Script for setting up the OpenBTS environment with SDR
# Version 0.1

#Instructions:
#Place setup.sh in folder called /scripts
#export PATH="$PATH:~/scripts"
#chmod u+x setup.sh
#If the script is not in the PATH, run it with sudo ./setup.sh
clear
echo "PCI Setup Script Starting"

#TODO add-apt commands
apt-get update
apt-get install subversion
echo "Subversion installed"
apt-get install vim
echo "Vim installed"
apt-get install git
echo "Git installed"

echo "Bladerf library installation starting"

#For Ubuntu 14.04 or later
apt-get install software-properties-common python-software-properties
add-apt-repository ppa:bladerf/bladerf
apt-get update
sudo apt-get install bladerf

apt-get install libbladerf-dev

apt-get install bladerf-firmware-fx3
apt-get install bladerf-fpga-hostedx40

echo "Bladerf library installation complete"

echo "Installing other dependencies"
sudo apt-get install $(
    wget -qO - https://raw.githubusercontent.com/RangeNetworks/dev/master/build.sh | \
    grep installIfMissing | \
    grep -v "{" | \
    cut -f2 -d" ")

add-apt-repository ppa:chris-lea/zeromq
apt-get update
apt-get install libzmq3-dbg libzmq3-dev

#TODO - Build UHD from source
#apt-get install libboost-all-dev libusb-1.0-0-dev python-mako doxygen python-docutils cmake build-essential
#git clone git://github.com/EttusResearch/uhd.git
bash -c 'echo "deb http://files.ettus.com/binaries/uhd/repo/uhd/ubuntu/`lsb_release -cs` `lsb_release -cs` main" > /etc/apt/sources.list.d/ettus.list';
apt-get update;
apt-get install -t `lsb_release -cs` uhd

#TODO install OpenBTS
DIRECTORY=/openbts
cd /home
if [ -d "$DIRECTORY" ]; then
	mkdir /home/$DIRECTORY
fi
cd $DIRECTORY

git clone https://github.com/RangeNetworks/openbts.git
git clone https://github.com/RangeNetworks/smqueue.git
git clone https://github.com/RangeNetworks/subscriberRegistry.git
 
#Build OpenBTS
for D in *; do (
    echo $D;
    echo "=======";
    cd $D;
    git clone https://github.comRangeNetworks/CommonLibs.git;
    git clone https://github.com/RangeNetworks/NodeManager.git);
done;
git clone https://github.com/RangeNetworks/libcoredumper.git;
git clone https://github.com/RangeNetworks/liba53.git

#Build libcoredumper
cd libcoredumper;
./build.sh && \
   sudo dpkg -i *.deb;
cd ..

#Build liba53
cd liba53;
make && \
   sudo make install;
cd ..;

svn checkout http://voip.null.ro/svn/yatebts/trunk yatebts
#NOTE: They have modified the bladeRFDevice.cpp since I wrote this and now lines 112 through 133 should be commented out.
#Since they most likely will modify it again in the future, look for bladerf_fpga_size bfs; and
#place the #ifdev NEVER on the line immediately before that and the #endif on the line before switch (bladerf_device_speed(bdev)). 
#Since this placement might also change in the future, remember that you are commenting out the bit that loads the bladeRF FPGA.
vim ./yatebts/mbts/TransceiverRAD1/bladeRFDevice.cpp "+108s/^/#ifdef NEVER" +129s/^/#endif +wq
echo "YateBTS cloned"

cd $DIRECTORY/yatebts
./autogen.sh
vim configure +4263,4291s/^/#/ +wq
./configure

cd /home/openbts/obts/yatebts/mbts/Peering
make
cd /home/openbts/obts/yatebts/mbts/TransceiverRAD1
make


#Configure OpenBTS
mkdir /etc/OpenBTS
cd /etc/OpenBTS
sqlite3 -init ./apps/OpenBTS.example.sql /etc/OpenBTS/OpenBTS.db ".quit"

#TEST
#sqlite3 /etc/OpenBTS/OpenBTS.db .dump
#TODO CHange to correct directory name
cd /home/openbts/obts/openbts/apps
./OpenBTS

#Create subscriber registry
mkdir -p /var/lib/asterisk/sqlite3dir

#Build sipauthserve
cd subscriberRegistry
./autogen.sh
./configure
make
#TODO - change main directory name
cd /home/openbts/obts/subscriberRegistry
sqlite3 -init subscriberRegistry.example.sql /etc/OpenBTS/sipauthserve.db ".quit"
