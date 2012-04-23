
module(..., package.seeall)	

local input

local function findText(text, iteration)
	iteration = iteration or 10
	for i = 1, iteration do
		input = com.read()
		if input then
			if input:find(text) then 
				print(text .." found")
				return true
			end
		end
	end
	print(text .. " not found")
	com.write("error\n\r")
end

local function mydelay(time)
	local tstart = tmr.start( 0 )
	local delta = 0
	while delta < (time) do
		local tend = tmr.read( 0 )
		delta = tmr.gettimediff( 0, tstart, tend )
		coroutine.yield()
	end
	print("delay of "..time.."us done")
end

function on()
	mydelay(300000)
	com.write("$$$")
	mydelay(300000)
	findText("CMD")
end

function off()
	com.write("exit\r")
	mydelay(100000)
	findText("EXIT")
end

function setDeviceid(s)
	on()
	local deviceid = string.gsub(s, " ", "$")		--Leerschläge mit $ ersetzen
	com.write("set opt deviceid "..deviceid.."\r")
	mydelay(100000)
	findText("AOK")
	com.write("save\r")
	mydelay(100000)
	findText("Storing in config")
	off()
end

function getSettings(command)
	local settings = {}
	on()
	com.write("get "..command.."\r")
	mydelay(100000)
	if not findText("=") then print("errör") return end
	while input:find("=") do						--options abfüllen
		local index, value
		index, value = input:match("(.+)=(.*)")
		settings[index] = value
		input = com.read()
		if not input then break end					-- wenn input nil ist, schleife verlassen		
	end
	mydelay(10000)
	off()
	return settings
end
