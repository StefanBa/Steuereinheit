-------------------------------------------------------------------------------
-- FHNW			Studiengang EIT
-- Projekt6		Android-basiertes Home Automation System
-- Web			http://web.fhnw.ch/technik/projekte/eit/Fruehling2012/BaumKell/
-- @author		Stefan Baumann, stefan.baumann1@students.fhnw.ch
-- @release		Datum: 17.08.2012
-- @description	Managet das Senden und Empfangen von Files
-------------------------------------------------------------------------------

module(..., package.seeall)

require "com"

local BLOCKSIZE = 64		--ohne checksumme
local TIMEOUT = 3000000
local TIMERID = nil			--Systemtimer
local ack = "ack\r\n"
local nak = "nak\r\n"
local TRIES = 2				--Anzahl Versuche 

-------------------------------------------------------------------------------
-- Erzeugt die Checksumme eines Strings und gibt diese zurück
-- @param		s String zur erzeugung der Checksumme
-- @return	 	Checksumme

local function checksum(s)
	local sum = 0
	local t = { s:byte(1,-1) }
	for i,v in ipairs(t) do
		sum = sum + v
	end
	return bit.band( sum,255 )
end

-------------------------------------------------------------------------------
-- Wartet auf UART-Daten der Grösse BLOCKSIZE und schreibt diese in das file.
-- Überprüft zuerst ob die Checksumme der Datenbytes (alle ausser das letzte) dem
-- Checksummenbyte (letztes Byte) entspricht.
-- @param		file file, in das geschrieben wird
-- @param	 	difflen optional, für letzter Block, falls dieser mit Nullen aufgefüllt wurde

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
		end
	end
	return false
end

-------------------------------------------------------------------------------
-- Liest Daten der grösse BLOCKSIZE aus file und sendet diese auf der UART-Schnittstelle.
-- Vorgängig wird die Checksumme berechnet und als letztes Byte angehängt.
-- @param		file file, von dem gelesen wird

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

-------------------------------------------------------------------------------
-- Wird aufgerufen um ein file zu empfangen. Erstellt oder Öffnet (-> Überschreibt)
-- das file, berechnet Anzahl Pakete und führt entsprechend "writeToFile" aus.
-- @param		filename Name des files
-- @param	 	filesize Grösse des files
-- @return		boolean true, falls Übertragung erfolgreich

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

-------------------------------------------------------------------------------
-- Wird aufgerufen um ein file zu senden. Versucht das file zu öffnen, berechnet
-- die Anzhal Pakete und ruft entsprechend "readFromFile" aus.
-- @param		filename Name des files
-- @param	 	filesize Grösse des files
-- @return		boolean true, falls Übertragung erfolgreich

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



