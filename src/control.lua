-------------------------------------------------------------------------------
-- FHNW			Studiengang EIT
-- Projekt6		Android-basiertes Home Automation System
-- Web			http://web.fhnw.ch/technik/projekte/eit/Fruehling2012/BaumKell/
-- @author		Stefan Baumann, stefan.baumann1@students.fhnw.ch
-- @release		Datum: 17.08.2012
-- @description	Implementation des Protokolls. Erzeugt die Funktionsaufrufe dynamisch.
-------------------------------------------------------------------------------

module(..., package.seeall)

require "kit"
require "cmd"
require "file"
require "conf"
require "t"

set = {}												--müssen global sein, wegen loadstring
get = {}

local mode = "off"
local ack = "ack"
local ret = "ret"
local nak = "nak"

-------------------------------------------------------------------------------
-- Timer Handler Function. Ist das Android-Device im Remote-Modus, so wird diese
-- Funktion periodisch aufgerufen, und sendet die aktuellen IO-Werte.

local function tmr_handler()
	local t = {}
 	for i,v in pairs(conf.get("update", "*t")) do
		t[i] = kit.IO[v].real
 	end
 	com.write(ret,"remote",unpack(t))
end

-------------------------------------------------------------------------------
-- Initialisiert und konfiguriert das WLAN-Modul mittels der Persistenten Werten
-- der SD-Karte. So ist das WLAN-Modul nach jedem Reset anhand der SD-Karte
-- konfiguriert.

function init()
	cmd.on()
	set.boardid( true )
	set.devName( conf.get("devName"), true )
	set.time( "init", true )
	set.wlan( nil, nil, true)
	cmd.reboot()
	cpu.set_int_handler( cpu.INT_TMR_MATCH, tmr_handler )
end

-------------------------------------------------------------------------------
-- Sendet ein "ack" um ein Verbindungstest zu ermöglichen

function get.ack()
	com.write(ack)
end

-------------------------------------------------------------------------------
-- Verändert den deviceName der Steuereinheit. Dem Namen wird an hinterster Stelle
-- die MAC-Adresse des WLAN-Moduls angehängt um die Steuereinheit eindeutig
-- identifizieren zu können. Der deviceName wird zusätzlich auf der SD-Karte gespeichert.
-- @param		deviceId zu aktualisiernder deviceName
-- @param		nocmd optional, true für initialisierung

function set.devName(deviceId, nocmd)
	local s = " "
	local boardID = conf.get("boardID")
	conf.set("devName", {deviceId})
	deviceId = deviceId.. s:rep( 26 - deviceId:len() ) .. boardID	--boardID an hinterster Stelle anfügen
	deviceId = deviceId:gsub(" ", "$")								--Leerschläge mit $ ersetzen
	cmd.on(nocmd)
	cmd.set("set opt deviceid "..deviceId)
	cmd.off(nocmd)
	com.write(ack)
end

-------------------------------------------------------------------------------
-- Sendet aktueller deviceName des WLAN-Moduls.

function get.devName()
	cmd.on()
	local deviceId = cmd.get("get option", "DeviceId")
	cmd.save()
	cmd.off()
	com.write(ret, deviceId)
end

-------------------------------------------------------------------------------
-- Holt die MAC-Adresse des WLAN-Moduls und Speichert diesen auf der SD-Karte.
-- @param		nocmd optional, true für initialisierung

function set.boardid(nocmd)
	cmd.on(nocmd)
	local mac = cmd.get("get mac", "Mac Addr")
	cmd.off(nocmd)
	
	local mac2, mac1, mac0 = string.match(mac, "%w+:%w+:%w+:(%w+):(%w+):(%w+)")
	local boardID =  mac2 .. mac1 .. mac0
	mac, mac2, mac1, mac0 = nil, nil, nil, nil
	conf.set("boardID", {boardID})
	print( "boardID: ".. boardID )
end

-------------------------------------------------------------------------------
-- Konfiguriert die wlan-Parameter des WLAN-Moduls anhand der SD-Karte
-- @param		ssid optional, SSID vom Netzwerk (manuell nicht von SD-Karte)
-- @param		pw optional, zugehöriges Passwort (manuell nicht von SD-Karte)
-- @param		nocmd optional, true für initialisierung

function set.wlan(ssid, pw, nocmd)
	if not ssid then
		local wlan = conf.get("wlan", "*t")
		ssid = wlan[1]
		pw   = wlan[2]
	end
	ssid = ssid:gsub(" ", "$")
	pw = pw:gsub(" ", "$")
	cmd.on(nocmd)
	cmd.set("set w ssid " .. ssid)
	cmd.set("set w phrase " .. pw)
	cmd.save()
	cmd.off(nocmd)
end

-------------------------------------------------------------------------------
-- Führt die WPS-App des WLAN-Moduls aus. Die wlan-Konfigurationen werden auf
-- der SD-Karte gespeichert.

function set.wps()
	cmd.on()
	local success = cmd.wps()
	if success then
		cmd.findText("",3000000) 			--Zeit bis WLAN-Modul reboot, connect
		cmd.on()
		local ssid = cmd.get("get w", "SSID")
		local pw = cmd.get("get w", "Passphrase")
		cmd.off()
		conf.set("wlan", {ssid, pw})
	end
end

-------------------------------------------------------------------------------
-- Setzt IO-Werte. Ist das Program "on", so werden die "custom"-Werte aktualisiert,
-- so wird das debuggen vom Android-Device aus ermöglicht. Ist das Program "off",
-- werden die "real"-Werte aktualisiert, welche normalerweise verwendet werden.
-- @param		id ID vom Ein- oder Ausgang
-- @param		value Wert des Ein- oder Ausgangs. Mit "real" wird der Debug-Wert gelöscht.

function set.io(id, value)
	if value == "real" then
		kit.IO[id].custom = nil
		print("real", kit.IO[id].real)
		return
	end
	value = tonumber(value)
	if mode == "on" then
		kit.IO[id].custom = value
		print("custom", kit.IO[id].custom)
	else 
		kit.IO[id].real = value
		print("real", kit.IO[id].real)
	end
	coroutine.yield()
	com.write(ack)
end

-------------------------------------------------------------------------------
-- Sendet der aktuelle IO-Wert.
-- @param		id ID vom Ein- oder Ausgan

function get.io(id)
	com.write(ret, kit.IO[id].merge)
end

-------------------------------------------------------------------------------
-- Startet oder stoppt die Statemachine auf der SD-Karte in einer geschützter Umgebung.
-- Ein korruptes File erzeugt somit kein Crash. Die Variable PROGCOMPLETE dient zur
-- Überprüfung, ob das gesampte File vorhanden ist.
-- @param		s "on" für starten, "off" für stoppen

function set.program(s)
	if s == "on" then
		local state = pcall( function ()		--programm in geschützter Umgebung starten
			require"statemachine"
		end )
		print("state:   ", state)
		
		local success = false
		if state then
			if statemachine.PROGCOMPLETE then
				success = true
				print("program running")
				_G.threadend = #threads
				mode = "on"
				com.write(ack)
			end
		end
		if not success then
			print("load program failed")
			com.write(nak)
		end
		
	elseif s == "off" then
		mode = "off"
		_G.threadend = 4
		--coroutine.yield()
		--for i = 5, #threads do
		--	threads[i] = nil
		--end
		package.loaded["statemachine"] = nil		--unload prog
		_G["statemachine"] = nil
		kit.reset("custom")
		print("program stoped")
		com.write(ack)
	else
		return
	end
end

-------------------------------------------------------------------------------
-- Sendet der aktuelle zustand "on" oder "off" der Statemachine auf der SD-Karte.

function get.program()
	com.write(ret, "program", mode)
end

-------------------------------------------------------------------------------
-- Wird nach jeder Fileübertragung ausgeführt. Falls sie fehlerhaft war, wird 
-- überprüft, ob die Verbindung noch besteht weil dies während der Fileübertragung
-- nicht überprüft werden kann.
-- @param		success true, falls Übertragung erfolgreich

local function filetermination(success)
	if success then
		print("Übertragung erfolgreich")
	else
		print("Übertragung fehlgeschlagen")					--Verbindung Überprüfen
		cmd.on()
		local conn = cmd.get("show conn", false, "8")		--Nach String suchen, der 8 enthält (--> connection Status)
		cmd.off()
		if conn:sub(4,4) == "1" then						--falls "TCP-Status" == connected
			com.checkconnect(com.OPEN)
		else
			com.checkconnect(com.CLOS)
		end
	end
end

-------------------------------------------------------------------------------
-- Empfängt file vom Android-Device und stoppt das Programm
-- @param		filename Name des Files
-- @param		filesize Grösse des Files

function set.file(filename, filesize)
	set.program("off")		--Programm anhalten bei Config- oder Statemachine empfang
	local success = file.recv(filename, filesize)
	filetermination(success)
end

-------------------------------------------------------------------------------
-- Sendet file an das Android-Device
-- @param		filename Name des Files
-- @param		filesize Grösse des Files

function get.file(filename)
	filesize = mymod.getsize(filename)
	local success = file.send(filename, filesize)
	filetermination(success)
end

-------------------------------------------------------------------------------
-- Schreibt persistente Werte in die "conf"-Tabelle, welche auch auf der SD-Karte
-- aktualisiert wird.
-- @param		key Name des Eintrages
-- @param		... Werte des Eintrages

function set.store(key, ...)
	conf.set(key, {...})
	if key == "update" then
		kit.reset("real")
		kit.reset("custom")
		kit.reset("merge")
	end	
	com.write(ack)
end


-------------------------------------------------------------------------------
-- Sendet ein Eintrag der "conf"-Tabelle
-- @param		key Name des Eintrages

function get.store(key)
	com.write( ret, key, conf.get(key) )
end

-------------------------------------------------------------------------------
-- Startet oder stoppt den Remote-Modus. Ist er aktiv, so werden mittels Interrupt
-- periodisch die aktiven IO-Werte gesendet.
-- @param		s "on" um zu starten, "off" um zu beenden
-- @param		time optional, Periodizität in us, default 1s
-- @param		noack falls true, wird kein Ack gesendet

function set.remote(s , time, noack)
	local id = tmr.VIRT8
	local time = time or 250000	--min für VIRT-TMR: 250000
	if s == "on" then
		tmr.set_match_int( id, time, tmr.INT_CYCLIC );
		cpu.sei( cpu.INT_TMR_MATCH, id )		
		set.debug("off", true)
		if not noack then com.write(ack) end
		
	elseif s == "off" then
		kit.reset("custom")
		tmr.set_match_int( id, 0, tmr.INT_CYCLIC );
		cpu.cli( cpu.INT_TMR_MATCH, id )
		set.debug("off", true)
		if not noack then com.write(ack) end
		
	end
end

function set.debug(s, noack)
	if s == "on" then
		t.debug = true
		if not noack then com.write(ack) end
	elseif s == "off" then
		t.debug = false
		kit.reset("custom")
		if not noack then com.write(ack) end
	end
end

-------------------------------------------------------------------------------
-- Setzt die Uhrzeit anhand der Adresse des Timeservers, die auf der SD-Karte
-- gespeichert ist.
-- @param		arg optional Timestamp für manuelles Stellen der Uhr
-- @param		nocmd optional, true für initialisierung

function set.time(arg, nocmd)
	local time = tonumber(arg)
	local offset = 3600 * conf.get( "timezone" )
	local server = conf.get( "timeserver" )
	
	if not time then						--falls Zeit nicht manuell gestellt
		cmd.on(nocmd)
		cmd.set("set time ad " .. server)
		cmd.set("set time ena 1")
		cmd.save()
		time = cmd.get("show t t", "RTC")
		cmd.off(nocmd)
	end
	
	os.settime(time + offset)
	print( "time:    ", os.date() )
	if arg == "init" then return end		--falls Zeitinitialisierung, kein ack
	com.write(ack)	
end

-------------------------------------------------------------------------------
-- Sendet die aktuelle Zeit der Steuereinheit. Erstes Argument Timestamp,
-- zweites Argument formatierter String mit Wochentag, Uhrzeit und Datum

function get.time()
	com.write(ret,os.time(),os.date())
end

-------------------------------------------------------------------------------
-- Kreiert ein ausfürbarer String, der einem Funktionsaufruf der Protokollsfunktionen
-- entspricht. So können alle set und get-Funktionen über die UART-Schnittstelle
-- aufgerufen werden.
-- @param		data Tabelle mit Parameter für Funktionsaufruf

local function createfcall(data)					--Funktionsaufruf "zusammensetzen" --> alle Argumente werden Strings!!
	local fstring = data[1] .. "." .. data[2]
	if #data < 3 then
		fstring = fstring .. "()"
	else
		fstring = fstring.."([["..data[3].."]]"
		for i = 4, #data do
			fstring = fstring .. ",[[" .. data[i] .."]]"
		end
		fstring = fstring .. ")"
	end
	return loadstring("control."..fstring)
end

-------------------------------------------------------------------------------
-- Überprüft, ob die Funktion existiert, welche dynamisch aufgerufen werden soll.

local function checkName(name)
	for k in pairs(set) do
		if k == name then return true end
	end
	for k in pairs(get) do
		if k == name then return true end
	end
	return false
end

-------------------------------------------------------------------------------
-- Führt die von "createfcall" kreierte Funktion aus.
-- @param		input String mit Parameter für den Funktionsaufruf

function achieve(input)
	if #input > 1 then
		if not checkName(input[2]) then return end						--feher abfangen
		fcall = createfcall(input)
		fcall()
	end
end

-------------------------------------------------------------------------------
-- Funktion der Koroutine. Führt "achieve" aus, um eine Funktionsaufruf zu erzeugen.
-- Überprüft, ob WPS-Butten gedrückt wurde.

function run()
	local input = com.read()
	if input then
		achieve(input)
	end
	if kit.button_clicked(kit.BTN_WPS) then
		set.wps()
	end	
end
	