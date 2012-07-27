-------------------------------------------------------------------------------
-- FHNW			Studiengang EIT
-- Projekt6		Android-basiertes Home Automation System
-- Web			http://web.fhnw.ch/technik/projekte/eit/Fruehling2012/BaumKell/
-- @author		Stefan Baumann, stefan.baumann1@students.fhnw.ch
-- @release		Datum: 17.08.2012
-- @description	Übernimmt die Ansteuerung des Command-Mode vom WLAN-Modul.
-------------------------------------------------------------------------------

module(..., package.seeall)

require "com"	

local timer_id = 2
local input

-------------------------------------------------------------------------------
-- Wartet eine gewisse Zeit auf einen bestimmten Text und gibt diesen zurück
-- @param		text Text, auf den gewartet werden soll. Leerer String -> delay
-- @param	 	t Zeit in us (optional, default ist 2s)
-- @return		String, der den gesuchten Text enthält

function findText(text, t)
	time = t or 2000000		--default 2s
	local tstart = tmr.start( timer_id )
	while time > tmr.getdiffnow( timer_id, tstart ) do
		input = com.read()
		if input then
			if input:find(text) then 
				return input
			end
		end
		coroutine.yield()
	end
	if not t then							--falls die Funktion nicht als Delay verwendet wurde
		print(text)
		error("Text could not be found")
	end
end

-------------------------------------------------------------------------------
-- Geht in CMD-Mode.
-- @param		nocmd optional, wenn true so wird Funktion nicht ausgeführt

function on(nocmd)
	if nocmd then return end				--falls deaktivert (für init-prozess)
	com.status = "cmd"
	findText("",300000)
	uart.write(com.uart_id, "$$$")			-- kein Endzeichen senden
	findText("CMD")
end

-------------------------------------------------------------------------------
-- Verlässt CMD-Mode.
-- @param		nocmd optional, wenn true so wird Funktion nicht ausgeführt

function off(nocmd)
	if nocmd then return end				--falls deaktivert (für init-prozess)
	com.write("exit")
	findText("EXIT")
	com.status = "normal"
end

-------------------------------------------------------------------------------
-- Führt Befehl aus für WLAN-Modul. Wartet auf Bestätigung "AOK" des Moduls.
-- @param		command Befehl, wie er laut manual übergeben werden muss

function set(command)
	com.write(command)
	findText("AOK")
end

-------------------------------------------------------------------------------
-- Speichert die aktuelle Konfiguration des WLAN-Moduls. Wartet auf Bestätigung.

function save()
	com.write("save")
	findText("Storing in config")
end

-------------------------------------------------------------------------------
-- Führt ein Reboot des WLAN-Modules aus.

function reboot()
	com.write("reboot")
	com.status = "normal"
end

-------------------------------------------------------------------------------
-- Holt sich Konfigurationsdetails vom WLAN-Modul.
-- @param		command get-Command laut Manual ohne gesuchte Varible (letztes Argument)
-- @param		index Letztes Argument vom Command; Variable die abgefragt wird
-- @return		Wert der gesuchten Variable

function get(command, index)
	com.write(command)
	for i = 1, 100 do
		input = findText("=")					
		local indexNow, value = input:match("(.+)=(.*)")
		if index == indexNow then
			return value
		end
	end
	error("wifly returned not required index")
end

-------------------------------------------------------------------------------
-- Startet die WPS-App des WLAN-Moduls.
-- @return	 	true, falls wps erfolgreich

function wps()
	print("wps start")
	com.write("wps\r")
	local success = false
	while true do
		input = com.read()
		if input then
			if input:find("FAILED") then
				success = false
				break
			elseif input:find("SUCCESS") then
				success = true
				break
			end
		end
		coroutine.yield()
	end
	com.status = "normal"
	com.checkconnect("*CLOS*")		--Verbindung ist unterbrochen
	print("wps finished")
	return success
end
