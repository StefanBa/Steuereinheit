
module(..., package.seeall)

require "com"	

local input

local function findText(text, iteration)
	iteration = iteration or 10
	--local tstart = tmr.start(2)
	--while true do
	for i = 1, iteration do
		
		--local delta = tmr.getdiffnow( 2, tstart )
		input = com.read()
		if input then
			if input:find(text) then 
				print("found:   ", text, delta)
				return input
			end
		end
		coroutine.yield()
	end
	print("not found:", text)
end

local function mydelay(time)
	local tstart = tmr.start( 1 )
	local delta = 0
	while delta < (time) do
		delta = tmr.getdiffnow( 1, tstart )
		coroutine.yield()
	end
	print( "mydelay: ", time )
	--print("tstart:"..tstart, "tend:"..tend, "delta break:" .. delta)
end

function on()
	com.cmd_on = true
	mydelay(300000)
	uart.write(com.uart_id, "$$$")			-- kein Endzeichen senden
	mydelay(300000)
	findText("CMD")
end

function off()
	com.write("exit")
	mydelay(300000)
	findText("EXIT")
	com.cmd_on = false
end

function setDeviceid(s)
	local deviceid = string.gsub(s, " ", "$")		--Leerschläge mit $ ersetzen
	com.write("set opt deviceid "..deviceid)
	mydelay(100000)
	findText("AOK")
	
	com.write("save")
	mydelay(1500000)
	findText("Storing in config")

end

function getSettings(command)
	local settings = {}
	com.write("get "..command )
	mydelay(150000)
	input = findText("=")
	while input:find("=") do						--options abfüllen
		local index, value
		index, value = input:match("(.+)=(.*)")
		settings[index] = value
		input = com.read()
		if not input then break end					-- wenn input nil ist, schleife verlassen		
	end
	return settings
end
