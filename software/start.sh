#!/bin/bash
# Portable Cell Initiative
# Script for starting the OpenBTS environment to begin GSM operations
# Version 1.0

#WARNING: Must be run with sudo

clear
echo "PCI Start Script Starting"
DIRECTORY=openbts

cd /home/$DIRECTORY/smqueue/smqueue/; ./smqueue &
cd /home/$DIRECTORY/subscriberRegistry/apps/; ./sipauthserve &
cd /home/$DIRECTORY/openbts/apps
screen -S openbtsCLI ./OpenBTS
#cd /home/$DIRECTORY/openbts/apps; ./OpenBTSCLI &