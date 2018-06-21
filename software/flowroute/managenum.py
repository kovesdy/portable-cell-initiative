#Managenums will manage the active numbers on the SIP system by adding or removing routing from the regexroute.conf file
#Import necessary libraries
import os
import sys
import pprint
import json
import random
import string
import telnetlib
from flowroutenumbersandmessaging.flowroutenumbersandmessaging_client import FlowroutenumbersandmessagingClient as flclient

routefilepath = "regexroute.txt" #The configuration file for routing (in YateBTS)
localdb = "numbers.txt" #Data file that must be located at the same directory as the python files
mainclient = None
test_mobile_number = "19017670182" #Create main test number (of the owner) for testing SMS/MMS and handling error messages from the system

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

	try:
		return flclient(username, password) #Instantiate flowroute client
		#numbers_controller = client.numbers #Create numbers controller
		#routes_controller = client.routes #Create routes controller
		#messages_controller = client.messages #Create messaging controller
	except Exception, e:
		print e.message

def reloadYBTS():
	#Reload mbts to save configuration changes
	host = "localhost"
	port = 5038
	try:
		tn = telnetlib.Telnet(host, port) #Star the telnet connection
		tn.write("mbts reload\r") #Etner command to reload yatebts
		tn.close() #Close the telnet connection
	except Exception, e:
		print e.message

def getTelnetResponse(command):
	#Get the response data from a telnet command
	host = "localhost"
	port = 5038
	try:
		tn = telnetlib.Telnet(host, port) #Star the telnet connection
		tn.write("command\n") #Etner command to reload yatebts
		try:
			data = tn.read_eager()
			return data
		except Exception, e:
			print(e.message)
			return None
		tn.close() #Close the telnet connection
	except Exception, e:
		print e.message
		return None

#Writes the international (SIP) number and the IMSI to regexroute.conf
def addNumToRegexroute(sipnum, imsi):
	with open(routefilepath, "a") as routefile:
		routefile.write("^%s$=ybts/IMSI%s" % (str(sipnum),str(imsi)) + "\n")

#Give a certain phone number (num), it will remove this line from the file
def removeNumFromRegexroute(num):
	with open(routefilepath, "r+") as routefile:
		data = routefile.readlines() #Read all lines in the file
		routefile.seek(0) #Begin at byte 0
		for line in data: #For each line in the file
			if not line.strip().startswith("^" + str(num) + "$=ybts/IMSI"): #If the line does not start with the specific character sequence for deletion
				routefile.write(line) #Write the line back on to the file (Overwrite)
		routefile.truncate()

#Format for the numbers.txt file is:
#LOCALNUMBER,FLOWROUTENUMBER
#If LOCALNUMBER is "Notassigned" then there is no current assignment to that number
#getAvailableNums() reads every number not assigned and returns it as a list
def getAvailableNums():
	final_list = []
	try:
		with open(localdb, "r") as numbersfile:
			data = numbersfile.readlines()
			for line in data:
				if line.startswith('Notassigned'):
					final_list.append(line.split(',')[1])
	except Exception, e:
		print e.message
		return None
	return final_list

#Assignnewnumber takes the localnumber, finds an available international number, overrides the numbers.txt file to update it
#If there is no available number, then requests a new number and updates the entire system
#Takes the localnumber as input and returns the international number
def assignNewNumber(localnum):
	opennums = getAvailableNums()
	if len(opennums) == 0:
		#There are no available numbers, request a new one
		try:
			requestNewNumber()
		except TypeError:
			print 'Problem when querying the numbersfile in getAvailableNums'
	else:
		selected_number = opennums[0] #Selects the first available number on the list
		try:
			with open(localdb, "r+") as numbersfile:
				data = numbersfile.readlines()
				for indexer in range(0, len(data)):
					line = data[indexer]
					if line.endswith(selected_number): #If the specific line ends with the selected number
						data[indexer] = str(localnum) + "," + selected_number #Override the line entry in data from Notassigned to the local number
						break;
				#Now, override the entire numbers file with data again
				numbersfile.seek(0)
				for line in data:
					numbersfile.write(line) #Write line back to file
				numbersfile.truncate() #Finally, truncate the file
		except Exception, e:
			print e.message
			exit()
		return selected_number

#Delete a local number from numbers.txt
#Returns as output the international (SIP) number
def removeExistingNumber(localnum):
	sip_number = None
	with open(localdb, "r+") as numbersfile:
		data = numbersfile.readlines()
		for i in range(0, len(data)):
			line = data[i]
			if line.startswith(localnum):
				sip_number = line.split(',')[1]
				#Change it back to Notassigned
				data[i] = "Notassigned," + sip_number
		#Override existing file again
		numbersfile.seek(0)
		for line in data:
			numbersfile.write(line)
		numbersfile.truncate()
	return sip_number

#Requests a new number (buys it) from the SIP Flowroute system, finally, adds it to the existing route of the system
def requestNewNumber():
	client = init_client()
	numbers_controller = client.numbers #Create numbers controller
	print('Requesting a new number from Flowroute')
	#TODO search for a new phone number (that costs the right amount)
	#TODO purchase the phone number
	#TODO add the phone number to the correct route

#Grab all the current phone numbers available in the SIP and updates the numbers.txt to place any that aren't on there on there
def updateAccountPhoneNumbers():
	numbers_controller = init_client().numbers
	try:
		max_numbers_request = 30 #Update in the future
		result = numbers_controller.list_account_phone_numbers(None, None, None, max_numbers_request, None) #Asks for the current account phone numbers (limit is 30)
		available_numbers = [] #Initialize empty list for all phone numbers that we own in the account
		for i in range(0,len(result['data'])):
			available_numbers.append(result['data'][i]['id']) #Append to the list the "Id" or the phone number in each entry

		with open(localdb, "r") as numbersfile:
			data = numbersfile.readlines()

		for line in data: #For each line read in the numbers.txt
			if ',' in line:
				temp_number = line.split(',')[1] #Get the main number out of this line
				if temp_number in available_numbers: #If the temporary number already exists in the main available numbers from SIP provider
					available_numbers.remove(temp_number)
				else:
					print('Error: Extra number exists that is not being paid for (Critical):' + temp_number)
			else:
				print('Error, incorrect syntax used in numbers.txt')
				exit()

		#If there are still more numbers left, append them to the document and set them as not assigned
		if len(available_numbers) > 0:
			with open(localdb, "a") as numbersfile: #Open to append
				for num in available_numbers:
					numbersfile.write('Notassigned,' + num + "\n")
	except Exception, e:
		print('Error: On pulling and updating the account numbers from the SIP database (on flowroute)')
		print e.message


arglist = sys.argv
if len(arglist) > 1:
	print('Additional arguments entered.')
	if(arglist[1] == 'Manualupdate'): #grab the first extra argument given, i.e. python managenum.py EXTRAARG1
		updateAccountPhoneNumbers()
	elif(arglist[1] == 'Add'):
		#Will add a new number (when a new number is created) from existing SIP
		if len(arglist) > 3: #Requires 3 arguments after python, the 'add', the imsi, and the local number
			#First, check if the number is already in the numbers.txt and assigned
			with open(localdb, 'r') as numbersfile:
				data = numbersfile.readlines()
			for line in data:
				if line.startswith(arglist[3]):
					print('Number already exists in the database. Exiting.')
					exit()
			sip_number = assignNewNumber(arglist[3])
			addNumToRegexroute(sip_number, arglist[2])
			reloadYBTS()
		else:
			print('Not enough arguments given in the add function')
	elif(arglist[1] == 'Delete'):
		if len(arglist) > 2: #If there is an extra argument on the end (number 3)
			numToDelete = arglist[2] #The third argument is the number to delete (local one)
			intlnum = removeExistingNumber(numToDelete)
			if intlnum is not None:
				removeNumFromRegexroute(intlnum)
				reloadYBTS()
			else:
				print('Error: No entry was found for this local number')
		else:
			print("Not enough arguments given in the delete function")
	else:
		print('Incorrect argument type given')
else:
	print('Not enough arguments given for managenum.py')