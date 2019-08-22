

#Assigned Ports: 11995-11999

'''
import asyncio

async def main():
	reader, writer = await asyncio.open_connection(host='127.0.0.1', port=11995)
	writer.write("Shannon\n")
	data = await reader.readline()
	print('Received: {}'.format(data)
	writer.close()

if __name__ == '__main__':
	asyncio.run(main())
'''
import asyncio
async def main():
	reader, writer = await asyncio.open_connection('127.0.0.1', 11995)
	writer.write("Shannon\n".encode())
	data = await reader.readline()
	print('Received: {}'.format(data.decode()))
	writer.close()

if __name__ == '__main__':
	asyncio.run(main())
