#remember to use Python 3.7.2 

#Assigned Ports: 11995-11999
#Use servers: 06,07,09,10 

#FINAL VERSION as of 11:09 PM 

api_url = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?"
key=""

import aiohttp 
import asyncio
import time
import sys 
import json 
import re 

serverIDs = ["Goloman", "Hands", "Holiday", "Welsh", "Wilkes"] 
serverPorts = {"Goloman": 11995, "Hands": 11996, "Holiday": 11997, "Welsh": 11998, "Wilkes":11999}
#each server is mapped to array of servers it talks to
serverRelationships = {"Goloman":["Hands", "Holiday", "Wilkes"], "Hands":["Wilkes"], "Holiday":["Welsh", "Wilkes"], "Wilkes":["Goloman", "Hands", "Holiday"], "Welsh":["Holiday"]}

#keeps track of clients and: 
#most recent location, server last talked to, time of connection
clients_database = {}   



def report_bad_command(command): 
	print("? " + command + "\n")
	sys.exit(1)  

def log_error(message): 
	error_msg = "ERROR, " + message + "\n"	

############################ FLOODING implementation ############################

async def at(client, writer, message): 
	try: 
		writer.write(message.encode())
		await writer.drain() 
		writer.write_eof() 
		await log_to_file("AT output is:" + message + "\n")  
	except: 
		await log_to_file("Unable to send message: " + message + "\n")

async def log_to_file(message):
	curr_logfile = open(logfile_name, 'a+') 
	curr_logfile.write(message) 
	curr_logfile.close() 


#CLIENT=server that is propagating AT message to all the servers it talks to 
async def flood(client,message): 
	if client not in serverRelationships: 
		return 

	message_array = message.split() 	
	clientTime = message_array[5]
	relationships = serverRelationships[client]

	for partner in relationships: 
		if client  not in clients_database or clientTime  > clients_database[client]["time"]: 
			try: 
				partner_port = serverPorts[partner]
				reader, writer = await asyncio.open_connection('127.0.0.1', port=partner_port)
				await log_to_file("Connection made with " + partner + "\n")
			
				#write message to partner and mark 
				await at(partner,writer, message)
		
				await log_to_file(client + " sent message to its partner:" + partner + "\n")
				await log_to_file("Message sent: " + message + "\n") 
				await log_to_file("Closing connection with " + partner + "\n")
			
			except: 
				await log_to_file("Unable to connect with " + partner + "\n")


############################ IAMAT implementation ############################

def no_whitespace(s): 
	for char in s: 
		curr_char=char
		if curr_char.isspace(): 
			return False
	return True 

#check for badly formatted coordinates 
def splitCoordinates(rawCoords):
	if ("+" and "-") not in rawCoords: 
		log_error("bad coordinates supplied")
		sys.exit(1)
		return None 
	return rawCoords.replace("+", " +").replace("-", " -").split()


def format_at_message(serverID, timeDiff, dataCopy): 
	return "AT " + serverID + " " + str(timeDiff) + " " + dataCopy 


#message has: "IAMAT", "kiwi.cs.ucla.edu", "+34.068930-118.445127" ,"1520023934.918963997"]
async def valid_iamat(message): 
	message_string = " ".join(message) 
	if len(message) != 4: 
		log_error("bad IAMAT command supplied") 
		report_bad_command(message_string) 
	try: 
		float(message[3]) 
	except: 
		log_error("bad client send time supplied") 
		report_bad_command(message_string) 
	
	if not no_whitespace(message[1]): 
		log_error("bad clientID supplied") 
		report_bad_command(message_string) 

	coordinates = splitCoordinates(message[2])
	try: 
		latitude = float(coordinates[0])	
		longitude = float(coordinates[1]) 
	except: 
		log_error("bad coordinates supplied") 
		report_bad_command(message_string) 

	if latitude < -90 and latitude > 90: 
		log_error("invalid latitude coordinate supplied") 
		report_bad_command(message_string) 
	if longitude < -180 and longitude > 180: 
		log_error("invalid longitude coordinate supplied") 
		report_bad_command(message_string) 
	return True
 
async def iamat(writer, message, client, serverID, rawCoords, clientTime, realTime):
	timeDifference = float(clientTime) - realTime 
	
	coordinates = splitCoordinates(rawCoords)#check for returned array of size zero 
	if len(coordinates) < 2: 
		
		log_error("unable to process iamatmessage coordinates")
		report_bad_command(message_string) 

	msg_string = " ".join(message)
	clientData = msg_string.replace("IAMAT","").lstrip() 

	if client not in clients_database or clientTime  > clients_database[client]["time"]: 
		clients_database[client] = {"server":serverID, "location":coordinates, "timeDiff":timeDifference, "time": clientTime, "client_msg": clientData}

		#format and send message 
		at_response = format_at_message(serverID, timeDifference, clientData)
		await send_message(writer, at_response)

		await log_to_file("IAMAT output is:" + at_response+ "\n") 	

		#propogate message 
		await flood(serverID, at_response) #client here needs to be servername

############################ WHATSAT implementation ############################
#ex entry: {"kiwi.cs.ucla.edu":{"server": "servername", "location"=[lat, long], "time"=time}} 


#command is a list with all the parts of the WHATSAT
#i.e. WHATSAT kiwi.cs.ucla.edu 10 5 = ["WHATSAT", "kiwi...", "10", "5"] 
async def valid_whatsat(command): 
	command_string = " ".join(command) 

	if len(command) != 4: 
		log_error("invalid whatsat command supplied") 
		report_bad_command(command_string) 
	try: 
		float(command[2]) 
		float(command[3]) 
		return True 
	except: 
		log_error("invalid whatsat parameter supplied") 
		report_bad_command(command_string) 	
	if not no_white_space(message[1]):
		log_error("invalid client ID supplied")  	
		report_bad_command(command_string) 
	return 	


def formURL(latitude ,longitude,radius): 
	url = '%slocation=%s,%s&radius=%d&key=%s' % (api_url,latitude, longitude, radius, key)
	return url 

#based on aiohttp documentation example
async def fetch(session, url): 
	async with session.get(url) as response: 
		return await response.json() 

def squeezeNewlines(s):
	return re.sub('\n\n+', '\n', s) 
 

#note client is the client that information is being requested on 
async def whatsat(writer, message, client, serverID, radius, infoBound):
	message_string = " ".join(message)  

	#error handlings  
	if float(radius) > 50: 
		log_error("please supply radius less than 50km")
		report_bad_command(message_string) 

	if float(infoBound)> 10: 
		log_error("please supply information limit less than 29 items") 
		report_bad_command(message_string) 

	if client not in clients_database: 
		log_error("client that info was requested on does not exist in database")
		report_bad_command(message_string) 
	
	client_info = clients_database[client]
	request_url = formURL(client_info["location"][0], client_info["location"][1], float(radius))
	async with aiohttp.ClientSession() as session: 
		api_data = await fetch(session, request_url)

		results = api_data["results"]
		
		#truncate results 
		results_new = results[0:int(infoBound)]
		api_data["results"] = results_new
		api_data_string = json.dumps(api_data)

		#squeeze newlines 
		api_data_string = squeezeNewlines(api_data_string)	
		api_data_string = api_data_string.rstrip("\n")	

		#format and send response 
		client_info = clients_database[client]	 	
		msg_header = format_at_message(client_info["server"], client_info["timeDiff"], client_info["client_msg"]) 
		# print("header is going to be " + msg_header)
		whatsat_response = msg_header + "\n" + api_data_string  
		await send_message(writer, whatsat_response)
		
		await log_to_file("WHATSAT output is:" + whatsat_response + "\n") 	


############################ SERVER STUFF  ############################

async def send_message(writer, message): 
		writer.write(message.encode())
		writer.write_eof()


async def handleClient(reader, writer):
	try: 
		data = await reader.read() 
	except: 
		log_error("couldn't read input from client")
		sys.exit(1)
	try: 
		data_decoded = data.decode() 
		message = data_decoded.strip().split() 
	except: 
		log_error("error in decoding")
		sys.exit(1) 


	message_string = " ".join(message) 

	for field in message: 
		if not no_whitespace(field): 
			log_error("white space in message field") 
			report_bad_command(message_string)
				
	message_type = message[0]
	client_name = message[1]

	if message_type != "IAMAT" and  message_type != "WHATSAT" and message_type != "AT":
		log_error("incorrect command supplied") 
		report_bad_command(message_string) 
		
	await log_to_file("Input to " + serverID + ": " + " ".join(message)+ "\n") #logging output handled within msg functions

	if message_type == "IAMAT":
		await valid_iamat(message) 
		rawCoords = message[2]
		clientTime = message[3]	
		await iamat(writer, message, client_name, serverID, rawCoords, clientTime, time.time()) 

	elif message_type == "WHATSAT":			
		await valid_whatsat(message) 	
		await whatsat(writer, message, client_name, serverID, message[2], message[3])

	elif message_type == "AT": 
		client_name = message[3]
		serverID_AT= message[1] 
		location = splitCoordinates(message[4])  
		client_data_arr = message[3:]
		await log_to_file("Received message:" + " ".join(message) + "\n")
		clientTime = message[4]
		#if new data store and flood 
		if client_name  not in clients_database or clientTime  > clients_database[client_name]["time"]: 
			clients_database[client_name] = {"server":serverID_AT, "location":location, "timeDiff":message[2], "time": message[5], "client_msg": " ".join(client_data_arr)}
			await flood(serverID, " ".join(message), ) 

	else:
		log_error("invalid command supplied:" + message_string)
		report_bad_command(message_string) 

############################ MAIN ROUTINE ############################
async def main(): 
		
	if len(sys.argv)!=2: 
		report_bad_command(" ".join(sys.argv)) 
	
	global serverID 
	global server 
	serverID = sys.argv[1]
	if serverID not in serverIDs:  
		report_bad_command(" ".join(sys.argv))

	try:  
		server = await asyncio.start_server(handleClient, host='127.0.0.1', port=serverPorts[serverID]) 
		global logfile_name 
		logfile_name = serverID + ".txt" 
		log_file= open(logfile_name, 'w+')
		log_file.write(serverID + "\n")
		log_file.write("Starting server:" + serverID + " at " + str(time.time())+ "\n")
		log_file.close() 
	except: 
		log_error("unable to start server") 
		report_bad_command(" ".join(sys.argv))

	await server.serve_forever()


if __name__=='__main__': 
	try:
		asyncio.run(main()) 
	except KeyboardInterrupt:
		server.close()
			 




