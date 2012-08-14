-------------------------------------------------------------------------------
-- FHNW			Studiengang EIT
-- Projekt6		Android-basiertes Home Automation System
-- Web			http://web.fhnw.ch/technik/projekte/eit/Fruehling2012/BaumKell/
-- @author		Stefan Baumann, stefan.baumann1@students.fhnw.ch
-- @release		Datum: 17.08.2012
-- @description	Erm�glicht das Abspeichern persistenter Werte auf der SD-Karte.
-------------------------------------------------------------------------------

module(..., package.seeall)

require "kit"
require "control"

_G.const = {}

local file

-------------------------------------------------------------------------------
-- Serialisiert eine Zahl, ein String oder eine Tabelle und Speichert das Resultat
-- in das momentan ge�ffnete file --> boardconf.lua. Kann auch mit verschachtelten 
-- Tabellen umgehen, wird dann rekursiv verwendet.
-- @param		o zu serialisierendes Objekt
-- @param		arg optional, zus�tzliches Argument um Formatierung zu erm�glichen

local function serialize(o, arg)
	if type(o) == "number" then
		file:write(o)
	elseif type(o) == "string" then
		file:write(string.format("%q", o))
	elseif type(o) == "table" then
		file:write("{\n")
		for k,v in pairs(o) do
			if arg then file:write(arg) end
			if type(k) == "string" then
				file:write("  ", k, " = ")
			end
			serialize(v, "\t")
			file:write(",\n")
		end
		if arg then file:write(arg) end
		file:write("}")
	end
end

-------------------------------------------------------------------------------
-- Speichert die globale Tabelle "const" mittels der Funktion "serialize" auf 
-- die SD-Karte

local function execute()
	file = io.open("/mmc/boardconf.lua", "w")
	file:write("_G.const = ")
	serialize(_G.const)
	file:write("\nCONFCOMPLETE = true\n")
	file:flush()
	file:close()
end

-------------------------------------------------------------------------------
-- F�llt die globale Tabelle "const" mit default-Werten.

local function default()
	_G.const = {
		boardID = {"none"},
		devName = {"SARHA"},
		wlan = {"SSID", "PASSWORD"},	--SSID, Password
		timezone = {"2"},
		timeserver = {"62.2.85.147"},
		cfg		= {"0", "0", "0"},								--Name, CreateID, ChangeID
		prg		= {"0", "0", "0"},
		update = kit.SORT
	}
end

-------------------------------------------------------------------------------
-- Initialisiert die persistenten Werte entweder von der SD-Karte. Sind diese
-- nicht verf�gbar, werden die default-Werte verwendet.

function init()
	local state = pcall( function ()
			dofile("/mmc/boardconf.lua")
		end )
		
	if ( state and CONFCOMPLETE ) then
		print("updated _G.const with file")
	else											
		default()
		execute()
		print("updated _G.const with init-values")
	end
end

-------------------------------------------------------------------------------
-- Erzeugt oder ver�ndert ein Eintrag in der "const" Tabelle und aktualisiert
-- File auf der SD-Karte.
-- @param		id Name des Wertes
-- @param		value zu speichernder Wert

function set(id, value)
	_G.const[id] = value			--falls id nochnicht existiert -> erzeugen
	execute()
end

-------------------------------------------------------------------------------
-- Gibt ein Eintrag der "const" Tabelle zur�ck. Ist der Eintrag eine Tabelle, so
-- werden default mehrere R�ckgabewerte erzeugt. Es kann auch die Tabelle selbst
-- verlangt werden.
-- @param		id Name des Eintrages
-- @param		format Tabelle als R�ckgabewert wenn "*t"
-- @return		Gespeicherte Werte vom entsprechenden Eintrag.

function get(id, format)
	if format == "*t" then
		return _G.const[id]
	end
	return unpack( _G.const[id] )
end

