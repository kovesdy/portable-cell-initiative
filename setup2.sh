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
echo "Bladerf library installation starting"

#For Ubuntu 14.04 or later
apt-get update
apt-get install git

apt-get install software-properties-common python-software-properties
add-apt-repository ppa:bladerf/bladerf
apt-get update
sudo apt-get install bladerf

apt-get install libbladerf-dev

apt-get install bladerf-firmware-fx3
apt-get install bladerf-fpga-hostedx40

echo "Bladerf library installation complete"