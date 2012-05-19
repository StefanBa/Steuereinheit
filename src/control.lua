
module(..., package.seeall)

require "kit"
require "cmd"
require "file"
require "conf"

set = {}												--müssen global sein, wegen loadstring
get = {}

threadstart = 1
threadend = 2
boardID = ""

local mode = "stop"					--kann stop, run (oder debug??) sein
local ack = "ack"
local ret = "ret"

local function tmr_handler()
  get.store("update")
end

function init()
	--pio.pin.sethigh( kit.RstWLAN )
	cmd.on()
	local mac = cmd.getSettings("mac")
	cmd.off()
	local mac2, mac1, mac0 = string.match(mac["Mac Addr"], "%w+:%w+:%w+:(%w+):(%w+):(%w+)")
	boardID =  mac2 .. mac1 .. mac0
	mac, mac2, mac1, mac0 = nil, nil, nil, nil
	print("boardID = ".. boardID )
	cpu.set_int_handler( cpu.INT_TMR_MATCH, tmr_handler )
end

function get.ack()
	com.write(ret, ack)
end

function set.devName(deviceid)
	local s = " "
	deviceid = deviceid.. s:rep( 26 - deviceid:len() ) .. boardID
	cmd.on()
	cmd.setDeviceid(deviceid)
	local option = cmd.getSettings("option")			--der Name zurückschreiben, der wirklich im Speicher steht
	cmd.off()
	if option.DeviceId == deviceid then
		com.write(ack)
	end
end

function get.devName()
	cmd.on()
	local option = cmd.getSettings("option")
	cmd.off()
	if option then
		com.write(ret, option.DeviceId)
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
	com.write(ack)
end

function get.io(id)
	com.write(ret, kit.IO[id].merge)
end

function set.program(s)
	if s == "run" then
		mode = "run"
		threadend = #threads
	elseif s == "stop" then
		mode = "stop"
		threadend = 4
		kit.reset("merge")
		kit.reset("custom")
	end
	com.write(ack)
end

function get.program()
	com.write(ret, mode)
end

function set.file(filename, filesize)
	print("recv in")
	file.recv(filename, filesize)
	print("recv out")
end

function get.file(filename)
	print("send in")
	filesize = mymod.getsize(filename)
	file.send(filename, filesize)
	print("send out")
end

function set.store(key, ...)
	if key == "update" then
		kit.reset("real")
		kit.reset("custom")
		kit.reset("merge")
		kit.update()
		local a = ...
		if a == "all" then
			conf.set(key, kit.SORT)
			com.write(ack)
			return
		end
	end
	conf.set(key, {...})
	com.write(ack)
end

function get.store(key)
	com.write(ret, key, unpack( conf.get(key) ) )
end

function set.remote(s , time)
	local id = tmr.VIRT0
	local time = time or 1000000	--min für VIRT-TMR: 250000
	if s == "on" then
		tmr.set_match_int( id, time, tmr.INT_CYCLIC );
		cpu.sei( cpu.INT_TMR_MATCH, id )
	elseif s == "off" then
		tmr.set_match_int( id, 0, tmr.INT_CYCLIC );
		cpu.cli( cpu.INT_TMR_MATCH, id )
	end
end

function set.cleanfile()
	file = io.open("/mmc/boardconf.lua", "w")
	file:write("")
	file:flush()
	file:close()
	print("boardconf.lua cleaned")
end

function get.settings(command)
	cmd.on()
	local settings = cmd.getSettings(command)
	cmd.off()
	for k,v in pairs(settings) do
		print(k .. " = " .. v .. "\r\n")
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

function achieve(input)
	if #input > 1 then
		if not checkName(input[2]) then return end						--feher abfangen
		fcall = createfcall(input)
		fcall()
	end
end

function run()
	local input = com.read()
	if input then
		achieve(input)
	end
end
	