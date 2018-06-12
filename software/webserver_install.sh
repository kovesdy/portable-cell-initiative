#!/bin/bash

#Setup the flask webserver on the odroid SBC
#Assumes python has already been installed from the main script
#Do not run script as sudo, only the first command needs to be

sudo apt-get install -y python-virtualenv
mkdir ~/webserv
cd ~/webserv
virtualenv venv

#Activate the environment
. venv/bin/activate

#Install flask
pip install flask

#To edit, activate the environment again and edit files
#Remember to enable webserver_start.sh on startup (in cron)

