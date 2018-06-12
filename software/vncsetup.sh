#!/bin/bash
#Please do not run as root
#Starts the vnc service (automatically if you want to)
#export DISPLAY=:0
#xrandr --fb 1920x1080
#x11vnc
x11vnc -display :0 -auth guess -rfbauth /home/odroid/.vnc/passwd
