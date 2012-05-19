
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
	print("SUMME:",sum)
	return bit.band( sum,255 )
end

local function writeToFile(file)	
	local count = 0
	
	while count ~= TRIES do
		count = count + 1
		local input = uart.read( com.uart_id, BLOCKSIZE + 1, TIMEOUT, TIMERID )
		print("input:",input)
	
		local dataBytes = input:sub(1,-2)
		local lastByte = string.byte( input:sub(-1) )
		local checksum = checksum( dataBytes )
		print("Checksum:" , checksum, "last byte:", lastByte )
		
		if checksum == lastByte then
			print("checksum", "ok")
			file:write( dataBytes )
			print("write:   ".. dataBytes)
			uart.write(com.uart_id, ack)
			return true
		else
			print("checksum", "not ok")
			uart.write(com.uart_id, nak)
		end
	end
	return false
end

local function readFromFile(file)
	local count = 0
	local output = file:read(BLOCKSIZE)
	local checksum = checksum(output)
	print("letztes byte von checksum:" .. checksum)
	
	local difflen = BLOCKSIZE - output:len()
	if difflen ~= 0 then
		print( "difflen is:", difflen)
		print( "output old:", output)
		output = output .. string.rep( string.char( 00 ), difflen)
		print( "output new:", output)
	end
	
	while count ~= TRIES  do
		count = count + 1
		print("count:  ", count)
		uart.write(com.uart_id, output .. string.char( checksum ) )
		print("data:   " , output .. string.char( checksum ) )					
		local input = uart.read( com.uart_id, ack:len(), TIMEOUT, TIMERID )
		if input == ack then return true end
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
		return
	end
	
	local nReceived = 0
	local nPakets = math.floor( filesize / BLOCKSIZE )		--Anzahl volle Pakete (Rest wird mit 0 aufgefüllt)
	local nRest = filesize % BLOCKSIZE
	if nRest ~= 0 then
		nPakets = nPakets + 1
	end	
	print( "Pakete:  ", nPakets)

	while nReceived ~= nPakets do
		if writeToFile( file, BLOCKSIZE ) then
			nReceived = nReceived + 1
			print( "PaketNR ok:", nReceived )
		end
	end
	print( "Übertragung erfolgreich" )
	file:flush()
	file:close()
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
		if readFromFile( file, BLOCKSIZE ) then
			nSent = nSent + 1
			print( "PaketNR ok:", nSent )
		else
			print("Übertragung fehlgeschlagen")
			break
		end
	end
	print("Übertragung erfolgreich")
	file:close()
end



