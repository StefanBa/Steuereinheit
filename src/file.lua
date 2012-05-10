
module(..., package.seeall)	

local UARTID = 0
local BLOCKSIZE = 64		--ohne checksumme
local TIMEOUT = 2000000
local TIMERID = nil			--Systemtimer
local ack = "ack\r\n"
local nak = "nak\r\n"

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
	local input = uart.read( UARTID, BLOCKSIZE + 1, TIMEOUT, TIMERID )
	print("input:",input)
	local count = 0
	
	local dataBytes = input:sub(1,-2)
	local lastByte = string.byte( input:sub(-1) )

	local checksum = checksum( dataBytes )
	print("Checksum:" , checksum, "last byte:", lastByte )
	
	if checksum == lastByte then
		print("checksum", "ok")
		file:write( dataBytes )
		print("write:   ".. dataBytes)
		uart.write(UARTID, ack)
		return true
	else
		print("checksum", "not ok")
		uart.write(UARTID, nak)
		return false
	end
end

local function readFromFile(file)
	local output = file:read(BLOCKSIZE)
	local checksum = checksum(output)
	print("letztes byte von checksum:" .. checksum)
	local count = 0
	
	local difflen = BLOCKSIZE - output:len()
	if difflen ~= 0 then
		print( "difflen is:", difflen)
		print( "output old:", output)
		output = output .. string.rep( string.char( 00 ), difflen)
		print( "output new:", output)
	end
	
	while count ~= 1  do
		count = count + 1
		print("count:  ", count)
		uart.write(UARTID, output .. string.char( checksum ) )
		print("data:   " , output .. string.char( checksum ) )					
		local input = uart.read( UARTID, ack:len(), TIMEOUT, TIMERID )
		if input == ack then return true end
	end
	
	return false
end

function recv(filename, filesize)

	local file = io.open( "/mmc/"..filename, "w" )
	if file then
		uart.write(UARTID, ack)
		print( "Open File:", filename )
	else
		uart.write(UARTID, nack)
		return
	end
	
	local nPakets = math.floor( filesize / BLOCKSIZE )		--Anzahl volle Pakete (Rest wird mit 0 aufgefüllt)
	local nRest = filesize % BLOCKSIZE
	if nRest ~= 0 then
		nPakets = nPakets + 1
	end	


	local nReceived = 0
	print( "Pakete:  ", nPakets)
	print( "Rest:    ", nRest )
	
	
	while nReceived ~= nPakets do
		if writeToFile( file, BLOCKSIZE ) then
			nReceived = nReceived + 1
			print( "PaketNR ok:", nReceived )
		end
	end
	
	file:flush()
	file:close()

end

function send(filename, filesize)
	
	if filesize then
		local file = io.open( "/mmc/"..filename, "r" )
		uart.write(UARTID, "ret;" .. filesize .. "\r\n")
	else
		uart.write(UARTID, nak)
		return
	end
	
	local input =  uart.read( UARTID, 5, TIMEOUT, TIMERID )
	
	if input == ack then
		print("ack received! :D")
	else
		print("ack not received! =(", input)
		uart.write(UARTID, nak)
		return
	end
	
	local nPakets = math.floor( filesize / BLOCKSIZE )			--Anzahl volle Pakete ohne Rest
	local nRest = filesize % BLOCKSIZE
	if nRest ~= 0 then
		nPakets = nPakets + 1
	end
	
	local nSent = 0
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
	print("file close")
	file:close()
end



