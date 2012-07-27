
module(..., package.seeall)

require "kit"
require "control"

_G.const = {}

local file

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

local function execute()
	file = io.open("/mmc/boardconf.lua", "w")
	file:write("_G.const = ")
	serialize(_G.const)
	file:write("\nCONFCOMPLETE = true\n")
	file:flush()
	file:close()
end

local function default()
	_G.const = {
		boardID = {"none"},
		devName = {"SARHA"},
		wlan = {"Not Your Business", "LM3S9D92embeddedluaX"},	--SSID, Password
		timezone = {"2"},
		timeserver = {"62.2.85.147"},
		cfg		= {"0", "0", "0"},								--Name, CreateID, ChangeID
		prg		= {"0", "0", "0"},
		update = kit.SORT
	}
end

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

function set(id, value)
	_G.const[id] = value			--falls id nochnicht existiert -> erzeugen
	execute()
end

function get(id, format)
	if format == "*t" then
		return _G.const[id]
	end
	return unpack( _G.const[id] )
end

