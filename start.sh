#!/bin/bash
# Portable Cell Initiative
# Script for starting the OpenBTS environment to begin GSM operations
# Version 1.0

#WARNING: Must be run with sudo

clear
echo "PCI Start Script Starting"
DIRECTORY=openbts
cd /home/$DIRECTORY

cd smqueue/smqueue/; sudo ./smqueue
cd subscriberRegistry/apps/; sudo ./sipauthserve
cd openbts/apps; sudo ./OpenBTS
cd openbts/apps; sudo ./OpenBTSCLI