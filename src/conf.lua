
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
	file:write("\nBOARDCONF = true\n")
	file:flush()
	file:close()
end

function update()
	local state = pcall( function ()
			dofile("/mmc/boardconf.lua")
		end )
		
	if ( state and BOARDCONF ) then
		print("updated _G.const with file")
	else											
		init()
		execute()
		print("updated _G.const with init-values")
	end
end

function init()
	_G.const = {
		boardID	= {control.boardID},
		configID	= {"none"},
		programID	= {"none"},
		update = kit.SORT
	}
end

function set(id, value)
	_G.const[id] = value			--falls id nochnicht existiert -> erzeugen
	execute()
end

function get(id)
	return _G.const[id]
end

