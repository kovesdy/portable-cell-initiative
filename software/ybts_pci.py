#Import necessary libraries
import os
import pprint
import json
import random
import string
from flowroutnumbersandmessaging.flowrouternumbersandmessaging_client import FlowroutenumbersandmessagingClient as flclient

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




