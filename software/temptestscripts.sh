#!/bin/bash

#This program logs the core temperatures to a log file

while true; do
echo "`date`,`cat /sys/devices/virtual/thermal/thermal_zone0/temp`,`cat /sys/devices/virtual/thermal/thermal_zone1/temp`,`cat /sys/devices/virtual/thermal/thermal_zone2/temp`,`cat /sys/devices/virtual/thermal/thermal_zone3/temp`,`cat /sys/devices/virtual/thermal/thermal_zone4/temp`" >> outdoors1.log
echo "Data logged"
sleep 60
done

