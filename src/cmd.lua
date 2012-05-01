
module(..., package.seeall)	

local input

local function findText(text, iteration)
	iteration = iteration or 10
	--local tstart = tmr.start(2)
	--while true do
	for i = 1, iteration do
		--local tend = tmr.read(2)
		--local delta = tmr.gettimediff( 2, tend, tstart  ) 
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
	com.write("error\n\r")
end

local function mydelay(time)
	local tstart = tmr.start( 1 )
	local delta = 0
	while delta < (time) do
		local tend = tmr.read( 1 )
		delta = tmr.gettimediff( 1, tend, tstart  )
		coroutine.yield()
	end
	print( "mydelay: ", time )
	--print("tstart:"..tstart, "tend:"..tend, "delta break:" .. delta)
end

function on()
	mydelay(300000)
	com.write("$$$")
	mydelay(300000)
	findText("CMD")
end

function off()
	com.write("exit\r")
	mydelay(300000)
	findText("EXIT")
end

function setDeviceid(s)
	local deviceid = string.gsub(s, " ", "$")		--Leerschläge mit $ ersetzen
	com.write("set opt deviceid "..deviceid.."\r")
	mydelay(100000)
	findText("AOK")
	
	com.write("save\r")
	mydelay(1500000)
	findText("Storing in config")

end

function getSettings(command)
	local settings = {}
	com.write("get "..command.."\r")
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
