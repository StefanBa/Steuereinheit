
module(..., package.seeall)

require "kit"
require "cmd"
require "file"
require "conf"

set = {}												--müssen global sein, wegen loadstring
get = {}

local mode = "stop"					--kann stop, run (oder debug??) sein
local ack = "ack"
local ret = "ret"
local nak = "nak"

local function tmr_handler()
	local t = {}
 	for i,v in pairs(conf.get("update", "*t")) do
		t[i] = kit.IO[v].real
 	end
 	com.write(ret,"remote",unpack(t))
end

function init()
	cmd.on()
	set.boardid( true )
	set.devName( conf.get("devName"), true )
	set.time( "init", true )
	set.wlan( nil, nil, true)
	cmd.reboot()
	cpu.set_int_handler( cpu.INT_TMR_MATCH, tmr_handler )
end

function get.ack()
	com.write(ret, ack)
end

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

function get.devName()
	cmd.on()
	local deviceId = cmd.get("get option", "DeviceId")
	cmd.save()
	cmd.off()
	com.write(ret, deviceId)
end

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
		local state = pcall( function ()		--programm in geschützter Umgebung starten
			require"progi"
		end )
		
		if ( state and prog.PROGCOMPLETE ) then
			print("program running")
			_G.threadend = #threads
			mode = "run"
			com.write(ack)
		else
			print("load program failed")
			com.write(nak)
		end
	elseif s == "stop" then
		mode = "stop"
		_G.threadend = 4
		--coroutine.yield()
		--for i = 5, #threads do
		--	threads[i] = nil
		--end
		package.loaded["prog"] = nil		--unload prog
		_G["prog"] = nil
		kit.reset("merge")
		kit.reset("custom")
		print("program stoped")
		com.write(ack)
	else
		return
	end
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
	com.write( ret, key, conf.get(key) )
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
		com.write(ack)
	end
end

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

function get.time()
	com.write(ret,os.time(),os.date())
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
	if kit.button_clicked(kit.BTN_WPS) then
		set.wps()
	end	
end
	