
module(..., package.seeall)	

local UARTID = 0
local BLOCKSIZE = 64
local TIMEOUT = 5000000
local TIMERID = nil			--Systemtimer
local input = ""

function checksum(s)
	local sum = 0
	local t = { s:byte(1,-1) }
	for _,v in ipairs(t) do
		sum = sum + v
	end
	print("SUMME:",sum)
	return bit.band( sum,255 )
end

local function writeToFile(file)
	input = uart.read( UARTID, BLOCKSIZE + 1, TIMEOUT, TIMERID )
	print("input:",input)
	
	local lastByte = string.byte( input:sub(-1) )
	local checksum = checksum( input:sub(1,-2) )
	print("Checksum:" , checksum, "last byte:", lastByte )
	
	if checksum == lastByte then
		print("checksum", "ok")
		file:write( input:byte() )
		print("write:   ".. input)
		uart.write(UARTID, "ack\n\r")
		return true
	else
		print("checksum", "not ok")
		uart.write(UARTID, "nak\n\r")
		return false
	end

end


function recv(filename, filesize)
	local nPakets = math.floor( filesize / BLOCKSIZE ) + 1		--Anzahl volle Pakete (Rest wird mit 0 aufgefüllt)
	local nRest = filesize % BLOCKSIZE
	local nReceived = 0
	local input = ""
	print( "Pakete:  ", nPakets)
	print( "Rest:    ",nRest )

	local file = io.open("/mmc/"..filename, "w")
	print( "Open File:", filename )
	uart.write(UARTID, "ack\n\r")
	
	while nReceived ~= nPakets do
		if writeToFile(file, BLOCKSIZE) then
			nReceived = nReceived + 1
			print("PaketNR ok:", nReceived)
		end
	end
	
	file:flush()
	file:close()
	--if nRest then wirteToFile(file, nRest) end

end



