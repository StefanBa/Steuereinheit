local kit = require( "kit" )
local cmd = require("cmd")
local mode = "stop"
threadend = 2


module(..., package.seeall)								--koroutinen und loadstring braucht explizit _G

local count = 0
local input = nil
set = {}												--müssen global sein, wegen loadstring
get = {}

function set.devName(deviceid)
	cmd.setDeviceid(deviceid)
	local option = cmd.getSettings("option")			--der Name zurückschreiben, der wirklich im Speicher steht (2x im CMD-Mode :/)
	if not option then return end						--debug..entfernen!!
	com.write("ack.devName."..option.DeviceId.."\r\n")	 
	--com.write("ack.devName."..deviceid.."\r\n")
end

function get.devName()
	print("hello from getdevName")
	local option = cmd.getSettings("option")
	if not option then return end						--debug..entfernen!!
	com.write("ret.devName."..option.DeviceId.."\r\n")	
end

function get.settings(command)
	local settings = cmd.getSettings(command)
	for k,v in pairs(settings) do
		com.write(k .. " = " .. v .. "\n\r")
	end
end

function set.io(id, value)
	if value == "real" then
		kit.IO[id].custom = nil
		print("real", kit.IO[id].real)
		return
	end
	value = tonumber(value)
	if mode == "run" then
		kit.IO[id].custom = value
		print("custom", kit.IO[id].custom)
	else 
		kit.IO[id].real = value
		print("real", kit.IO[id].real)
	end
end

function get.io(id)
	com.write("ret.io" .. kit.IO[id].merge)
end

function set.mode(s)
	if s == "run" then
		mode = "run"
		threadend = #threads
	elseif s == "stop" then
		mode = "stop"
		threadend = 2
		print("DOUT0 real",kit.IO.DOUT0.real)
		kit.reset()
	end
end

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

local function checkName(name)
	for k in pairs(set) do
		if k == name then return true end
	end
	for k in pairs(get) do
		if k == name then return true end
	end
	return false
end

function achieve(s)
	local splitter = {}
	for k in s:gmatch("[^%.]+") do
		splitter[#splitter + 1] = k
	end
	if #splitter > 1 then
		if not checkName(splitter[2]) then return end						--feher abfangen
		fcall = createfcall(splitter)
		fcall()
	end
end

function run()
	input = com.read()
	if input then achieve(input) end
end
	