#Automatically manage international numbers
#Assign a number that each phone can use dynamically, based on what is listed in nipc list registered
import os
import sys
from time import sleep
import telnetlib
from flowroutenumbersandmessaging.flowroutenumbersandmessaging_client import FlowroutenumbersandmessagingClient as flclient

routefilepath = "/usr/local/etc/yate/regexroute.conf" #The configuration file for routing (in YateBTS)
localdb = "numbers.txt" #Data file that must be located at the same directory as the python files
sleepTime = 10

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

def reloadConfig(tn):
	#Reload mbts to save configuration changes
	try:
		tn.write("nipc reload\r") #Etner command to reload yatebts configuration of subscribers
		sleep(0.5)
		tn.read_very_eager()
	except Exception, e:
		print e.message

def getRegisteredNums(tn):
	try:
		tn.write("nipc list registered\r")
		sleep(0.5)
		data = tn.read_very_eager()
		data = data.split("\r\n")
		if data[0].startswith("IMSI"): #Error checking
			del data[0:2] #Remove the first two indices
			del data[-1] #Remove the last index
			#Process data
			imsilist = []
			numlist = []
			for i in range(0, len(data)):
				item = data[i]
				itemSep = item.split('   ') #Seperate items into the two columns printed
				imsilist.append(itemSep[0])
				numlist.append(itemSep[1])
			return (imsilist, numlist)
		else:
			print("Error when accessing nipc list registered.")
			return () #Return empty tuple on error
	except Exception, e:
		print(e.message)
		return None

#Writes the international (SIP) number and the IMSI to regexroute.conf
def addNumToRegexroute(sipnum, imsi):
	sipnum = sipnum.replace('\n', '')
	imsi = imsi.replace('\n', '')
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

#Return all data from numbers.txt
def getDbData():
	localnumlist = []
	intlnumlist = []
	try:
		with open(localdb, "r") as numbersfile:
			data = numbersfile.readlines()
			for line in data:
				if ',' in line: #Verify that each line is valid and contains a comma
					line = line.replace('\n', '')
					splitdata = line.split(',')
					localnumlist.append(splitdata[0])
					intlnumlist.append(splitdata[1])
		return (localnumlist, intlnumlist)
	except Exception, e:
		print e.message
		return () #return empty tuple

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

#Given a local number that has not been assigned and an international num waiting for assignment,
#Update numbers.txt to match the two numbers together
def matchNumToDB(localnum, selectedintlnum):
	try:
		with open(localdb, "r+") as numbersfile:
			data = numbersfile.readlines()
			for indexer in range(0, len(data)):
				line = data[indexer]
				if line.endswith(selectedintlnum): #If the specific line ends with the selected number
					data[indexer] = str(localnum) + "," + selectedintlnum #Override the line entry in data from Notassigned to the local number
					break;
			#Now, override the entire numbers file with data again
			numbersfile.seek(0)
			for line in data:
				numbersfile.write(line) #Write line back to file
			numbersfile.truncate() #Finally, truncate the file
	except Exception, e:
		print e.message
		exit()

#Grab all the current phone numbers available in the SIP and updates the numbers.txt to place any that aren't on there on there
def updateAccountPhoneNumbers():
	numbers_controller = init_client().numbers
	try:
		max_numbers_request = 30 #Update in the future
		result = numbers_controller.list_account_phone_numbers(None, None, None, max_numbers_request, None) #Asks for the current account phone numbers (limit is 30)
		available_numbers = [] #Initialize empty list for all phone numbers that we own in the account
		for i in range(0,len(result['data'])):
			available_numbers.append(result['data'][i]['id'].encode('utf-8')) #Append to the list the "Id" or the phone number in each entry

		with open(localdb, "r") as numbersfile:
			data = numbersfile.readlines()
		for line in data: #For each line read in the numbers.txt
			if ',' in line:
				line = line.replace('\n', '') #Remove newline characters
				temp_number = line.split(',')[1] #Get the main number out of this line
				if str(temp_number) in available_numbers: #If the temporary number already exists in the main available numbers from SIP provider
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

if __name__ == "__main__":
	connectionOn = False #boolean of whether the telnet connection can be established
	telnetHOST = "127.0.0.1"
	telnetPORT = 5038
	while not connectionOn:
		try:
			tn = telnetlib.Telnet(telnetHOST, telnetPORT) #Start the telnet connection
			sleep(0.5)
			tn.read_very_eager() #Clear output from connection
		except Exception, e:
			print e.message
			print("Waiting for yatebts to restart.")
			sleep(20) #Wait for 20 seconds and try again
		else:
			connectionOn = True
			print("Connection established.")

	updateAccountPhoneNumbers()
	counter = 0 #How many times the loop has been made
	while True: #Repeat forever
		if counter >= 10: #If 10 loops have been made
			counter = 0 #Reset the counter
			updateAccountPhoneNumbers() #Start the update process from flowroute again
		#Find all local numbers and imsis
		(imsilist, numlist) = getRegisteredNums(tn)
		#Crossreference with numbers (intl.) database
		(localnums, intlnums) = getDbData()
		for num_inyate in numlist: #For each local phone number pulled from nipc list registered
			if num_inyate in localnums: #If there is a cross-reference match
				numlist.remove(num_inyate) #Remove from both lists
				localnums.remove(num_inyate)

		#Get available numbers (and cull from numbers.txt list)
		available_intl = []
		for i in range(0, len(localnums)):
			num_indatabase = localnums[i]
			if num_indatabase is 'Notassigned':
				available_intl.append(intlnums[i])
		for num_indatabase in localnums:
			if num_indatabase is 'Notassigned':
				localnums.remove(num_indatabase)

		#Any remaining numbers in numlist are needynums and any remaining in localnums are extranums
		#First, remove all extranums from regexroute, re-update numbers.txt to make any international number unassigned
		for num in localnums:
			removeNumFromRegexroute(num)
			newSipnumber = removeExistingNumber(num)
			if newSipnumber is not None: #Error checking
				available_intl.append(newSipnumber) #The new-non assigned number is now available for re-assignment when the cycle continues

		#Next, starting with first localnum in nipc list, try to assign each to an intl number both in numbers.txt and in regexroute
		for num in numlist:
			if len(available_intl) > 1: #If there are available international numbers
				currentimsi = imsilist[numlist.index(num)] #Get corresponding imsi for this particular num
				matchNumToDB(num, available_intl[-1])
				addNumToRegexroute(available_intl[-1], currentimsi)
				del available_intl[-1]
			elif len(available_intl) > 0: #If there is only one international number left
				currentimsi = imsilist[numlist.index(num)] #Get corresponding imsi for this particular num
				matchNumToDB(num, available_intl[0])
				addNumToRegexroute(available_intl[0], currentimsi)
			else:
				print('Not enough international numbers')
				print('TODO: finish method for buying new numbers')
		reloadConfig(tn) #Reload mbts		

		counter = counter + 1
		sleep(sleepTime)
