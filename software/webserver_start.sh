#!/bin/bash

#Purpose: Start the informational web server on reboot

cd ~/webserv
. venv/bin/activate
export FLASK_APP=hello.py
flask run
