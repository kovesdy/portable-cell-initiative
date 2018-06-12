import serial
import time
import telnetlib
import time

serialPORT = "/dev/ttyACM0"
telnetHOST = "localhost"
telnetPORT = 5038

try:
	ser = serial.Serial(serialPORT, 9600, timeout=1)
except Exception, e:
	print(e.message)
	exit(0)

def sendCommand(commandlist):
	commandlist.insert(0, 0xFE) #Inserts the incoming command character into the beginning
	for i in range(0, len(commandlist)):
		ser.write(chr(commandlist[i])) #Write the commands in order

def updateScreen(line1, line2):
	sendCommand([0x58]) #Clear the screen
	ser.write(line1 + "\r") #Writes first line with newline character
	ser.write(line2) #Writes second line

#i is an integer from 0 to 256 which describes the brightness of the screen
def setBrightness(i):
	sendCommand([0x99, i])

def setSplashScreen(line1, line2):
	command = [0x40]
	for char in line1:
		command.append(ord(char)) #Appends the unicode value of the given character for each character in the given strings
	for char in line2:
		command.append(ord(char))
	sendCommand(command) #Sets the splash screen

def getTelnetResponse(command):
	#Reload yatebts to save the changes
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

def sendTelnetCommand(tn, command):
	tn.write(command + "\r") #Write command to telnet with return character
	time.sleep(0.5) #Delay is necessary for telnet system to catch up
	data = tn.read_very_eager() #Read everything output right after sending write
	return data.split("\r\n") #Split the data by the newline symbols used by the yate telnet service

#setSplashScreen("Portable Cell", "Hermes 1")
#Reminder: set the splash screen in the initialization script
setBrightness(200) #Set initial brightness
updateScreen("Welcome", "Starting") #Set initial screen
print('Screen updated with test image')

state = "yateoff"
while True: #Loop forever (only exit on restart)
	#Initialize the telnet interface
	try:
		tn = telnetlib.Telnet(telnetHOST, telnetPORT) #Start the telnet connection
		time.sleep(0.5)
		tn.read_very_eager() #Clear output from connection
	except Exception, e:
		print e.message
		state = "yateoff"
	else:
		#If such an error does not occur (the telnet connection is made),
		state = "yateon" #Report that yate is operating
	
	if state == "yateoff":
		time.sleep(10) #If yate is not operating, sleep then check again
	elif state == "yateon": #When yate is on
		while True: #Loop forever (until the connection is closed, then report it)
			subscriber_number = "!"
			connection_number = "!"
			try:
				#Collect data from telnet
				subscribers_data = sendTelnetCommand(tn, "nipc list registered") #Check number of subscribers registered
				if subscribers_data[0].startswith("IMSI"): #If data is as expected
					subscriber_number = str(len(subscribers_data)-3)
				else:
					subscriber_number = "?"
				
				#Check the number of GPRS connections (lists active connections in most cases), except for checking chans during active calls
				gprs_data = sendTelnetCommand(tn, "mbts gprs stat")
				if gprs_data[0].startswith("GSM"): #Correct style of output
					connection_number = gprs_data[1].split()[4][-1] #Extract from string the number of active GPRS connections
				else:
					connection_number = "?"

				#Maybe check the uptime of the system, 
			except Exception, e: #When the connection closes
				print(e.message) #Purely print error for debugging purposes
				state = "yateoff" #Reset state to original
				time.sleep(5) #Prevent too many connection attempts to telnet by sleeping
				break #Exit out of secondary while loop
			else:
				#Write to the serial USB display
				if state == "yateon":
					status_string = "ON"
				elif state == "yateoff":
					status_string = "OFF"
				else:
					status_string = "N/A"
				line1 = "TOWER " + status_string
				line2 = "Reg: " + subscriber_number + "  Conn: " + connection_number
				if len(line2) == 17: #If characters exceed 16 characters on display
					line2 = "Reg: " + subscriber_number + " Conn: " + connection_number
				elif len(line2) > 17: #Even more space required
					print("Line 2 overflow error")
					line2 = "Reg " + subscriber_number + " Conn " + connection_number
				updateScreen(line1, line2) #Send update command to display
				time.sleep(10) #Sleep for 10 seconds, then start again
	else:
		print("Incorrect state reached.") #Should never reach an incorrect state
		exit(0)

ser.close()
