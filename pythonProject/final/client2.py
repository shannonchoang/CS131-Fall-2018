

#Assigned Ports: 11995-11999

#WHATSAT to Hands 
import asyncio
async def main():
	reader, writer = await asyncio.open_connection('127.0.0.1', 11995)
	#writer.write("IAMAT kiwi.cs.ucla.edu +34.068930-118.445127 1520023934.918963997".encode())
	writer.write("WHATSAT kiwi.cs.ucla.edu 10 5".encode())
	writer.write_eof()
	data = await reader.read()
	print('Received: {}'.format(data.decode()))
	writer.close()

if __name__ == '__main__':
	asyncio.run(main())
