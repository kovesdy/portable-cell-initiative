#Managenums will manage the active numbers on the SIP system by adding or removing routing from the regexroute.conf file
#Import necessary libraries
import os
import sys
import pprint
import json
import random
import string
import telnetlib
from flowroutnumbersandmessaging.flowrouternumbersandmessaging_client import FlowroutenumbersandmessagingClient as flclient

routefilepath = "/usr/local/etc/yate/regexroute.conf"
localdb = "numbers.txt"

def init_client():
	#Import secret keys from the os and print error messages if they do not exist
	if 'FR_ACCESS_KEY' in os.environ:
		username = os.environ.get('FR_ACCESS_KEY')
		print('Access Key acquired.')
	else:
		print('ERROR: No Access key in the OS environment')

	if 'FR_SECRET_KEY' in os.environ:
		password = os.environ.get('FR_SECRET_KEY')
		print('Secret key acquired.')
	else:
		print('ERROR: No Secret key in the OS Environment')

	test_mobile_number = "19017670182" #Create main test number (of the owner) for testing SMS/MMS and handling error messages from the system

	client = flclient(username, password) #Instantiate flowroute client
	numbers_cont = client.numbers #Create numbers controller
	routes_controller = client.routes #Create routes controller
	messages_controller = client.messages #Create messaging controller

def reloadYBTS():
	#Reload yatebts to save the changes
	host = "localhost"
	port = 5038
	tn = telnetlib.Telnet(host, port) #Star the telnet connection
	tn.write("ybts restart\n") #Etner command to reload yatebts
	tn.close() #Close the telnet connection

def addNumToRegexroute(num, imsi):
	try:
	routefile = open(routefilepath, "a") #Opens the regexroute.conf in appending mode
	routefile.write("^%s$=ybts/IMSI%s" % (str(num),str(imsi)) + "\n")
	routefile.close()

#Give a certain phone number (num), it will remove this line from the file
def removeNumFromRegexroute(num):
	routefile = open(routefilepath, "r+") #Opens the regexroute.conf in appending mode
	while(readline
	routefile.close()

arglist = sys.argv
if len(arglist) > 1:
	print('Additional arguments entered.')
	switch(arglist[1]): #grab the first extra argument given, i.e. python managenum.py EXTRAARG1
		case 'Add':
			#Will add a new number (when a new number is created) from existing SIP
			
		case 'Delete':
