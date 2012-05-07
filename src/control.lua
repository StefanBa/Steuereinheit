local kit = require( "kit" )
local cmd = require("cmd")
local mode = "stop"
local file = require("file")
threadend = 2


module(..., package.seeall)								--koroutinen und loadstring braucht explizit _G

local count = 0
local input = nil
local BOARD_ID
set = {}												--müssen global sein, wegen loadstring
get = {}

function init()
	--pio.pin.sethigh( kit.RstWLAN )
	cmd.on()
	local mac = cmd.getSettings("mac")
	cmd.off()
	local mac2, mac1, mac0 = string.match(mac["Mac Addr"], "%w+:%w+:%w+:(%w+):(%w+):(%w+)")
	BOARD_ID = mac2 .. mac1 .. mac0
	mac, mac2, mac1, mac0 = nil, nil, nil, nil
	print("BOARD_ID = ".. BOARD_ID)
end


function set.devName(deviceid)
	local s = " "
	deviceid = deviceid.. s:rep( 26 - deviceid:len() ) .. BOARD_ID
	cmd.on()
	cmd.setDeviceid(deviceid)
	local option = cmd.getSettings("option")			--der Name zurückschreiben, der wirklich im Speicher steht
	cmd.off()
	if option then
		com.write("ack\r\n")
	end
end

function get.devName()
	cmd.on()
	local option = cmd.getSettings("option")
	cmd.off()
	if option then
		com.write("ret;"..option.DeviceId.."\r\n")
	end
end

function get.settings(command)
	cmd.on()
	local settings = cmd.getSettings(command)
	cmd.off()
	for k,v in pairs(settings) do
		com.write(k .. " = " .. v .. "\r\n")
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
	coroutine.yield()
	com.write("ack\r\n")
end

function get.io(id)
	com.write("ret;" .. kit.IO[id].merge .. "\r\n")
end

function set.program(s)
	if s == "run" then
		mode = "run"
		threadend = #threads
	elseif s == "stop" then
		mode = "stop"
		threadend = 2
		kit.reset()
	end
	com.write("ack\r\n")
end

function get.program(s)
	com.write("ret;" .. mode .. "\r\n")
end

function set.file(filename, filesize)
	print("recv in")
	file.recv(filename, filesize)
	print("recv out")
end

function get.file(filename, filesize)
	print("send in")
	file.send(filename, filesize)
	print("send out")
end

function get.ack()
	com.write("ret;ack\r\n")
end

function set.talk(s)
	com.write(s)
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
	for k in s:gmatch("[^%;]+") do
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
	