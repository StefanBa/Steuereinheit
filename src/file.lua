
module(..., package.seeall)

require "com"

local BLOCKSIZE = 64		--ohne checksumme
local TIMEOUT = 2000000
local TIMERID = nil			--Systemtimer
local ack = "ack\r\n"
local nak = "nak\r\n"
local TRIES = 2

local function checksum(s)
	local sum = 0
	local t = { s:byte(1,-1) }
	for i,v in ipairs(t) do
		sum = sum + v
	end
	return bit.band( sum,255 )
end

local function writeToFile(file, difflen)	
	local count = 0
	local difflen = difflen or BLOCKSIZE
	print("difflen:  ", difflen)
	
	while count ~= TRIES do
		count = count + 1
		local input = uart.read( com.uart_id, BLOCKSIZE + 1, TIMEOUT, TIMERID )
	
		local dataBytes = input:sub( 1, -2 )
		local lastByte = string.byte( input:sub(-1) )
		local checksum = checksum( dataBytes )
		print("Checksum:" , checksum, "Last Byte:", lastByte )
		
		if checksum == lastByte then
			file:write( dataBytes:sub( 1, difflen ) )			--Überschüssige Nullen abschneiden
			uart.write(com.uart_id, ack)
			return true
		else
			uart.write(com.uart_id, nak)
			return false
		end
	end
	return false
end

local function readFromFile(file)
	local count = 0
	local output = file:read(BLOCKSIZE)
	local checksum = checksum(output)
	print("Checksum:" , checksum)
	
	local difflen = BLOCKSIZE - output:len()
	if difflen ~= 0 then
		print( "difflen is:", difflen)
		print( "output old:", output)
		output = output .. string.rep( string.char( 00 ), difflen)
		print( "output new:", output)
	end
	
	while count ~= TRIES  do
		count = count + 1
		uart.write(com.uart_id, output .. string.char( checksum ) )				
		local input = uart.read( com.uart_id, ack:len(), TIMEOUT, TIMERID )
		if input == ack then
			return true
		else
			return false
		end
	end
	
	return false
end

function recv(filename, filesize)
	local file = io.open( "/mmc/"..filename, "w" )
	if file then
		uart.write(com.uart_id, ack)
		print( "Open File:", filename )
	else
		uart.write(com.uart_id, nack)
		return false
	end
	
	local nReceived = 0
	local nPakets = math.floor( filesize / BLOCKSIZE )		--Anzahl volle Pakete (Rest wird mit 0 aufgefüllt)
	local nRest = filesize % BLOCKSIZE

	print( "Pakete:  ", nPakets)

	while nReceived ~= nPakets do
		if writeToFile( file ) then
			nReceived = nReceived + 1
			print( "PaketNR ok:", nReceived )
		else
			return false
		end
	end
	if nRest ~= 0 then						--letztes Paket
		if not writeToFile(file, nRest)	then
			return false
		end
	end						
	
	file:flush()
	file:close()
	return true
end

function send(filename, filesize)	
	if filesize then
		local file = io.open( "/mmc/"..filename, "r" )
		uart.write(com.uart_id, "ret;" .. filesize .. "\r\n")
	else
		uart.write(com.uart_id, nak)
		return
	end
	
	local input =  uart.read( com.uart_id, 5, TIMEOUT, TIMERID )
	if not ( input == ack ) then
		uart.write(com.uart_id, nak)
		return
	end
	
	local nSent = 0
	local nPakets = math.floor( filesize / BLOCKSIZE )			--Anzahl volle Pakete ohne Rest
	local nRest = filesize % BLOCKSIZE
	if nRest ~= 0 then
		nPakets = nPakets + 1
	end
	print( "Pakete:  ", nPakets)

	local file = io.open( "/mmc/"..filename, "r" )
	print( "Open File:", filename )
	
	while nSent ~= nPakets do
		if readFromFile( file ) then
			nSent = nSent + 1
			print( "PaketNR ok:", nSent )
		else
			return false
		end
	end
	file:close()
	return true
end



