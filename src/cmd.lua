
module(..., package.seeall)

require "com"	

local timer_id = 2
local input

local function findText(text, t)
	time = t or 2000000		--default 2s
	local tstart = tmr.start( timer_id )
	while time > tmr.getdiffnow( timer_id, tstart ) do
		input = com.read()
		if input then
			if input:find(text) then 
				return input
			end
		end
		coroutine.yield()
	end
	if not t then							--falls die Funktion nicht als Delay verwendet wurde
		error("Text could not be found")
	end
end

function on()
	com.cmd_on = true
	findText("",300000)
	uart.write(com.uart_id, "$$$")			-- kein Endzeichen senden
	findText("CMD")
end

function off()
	com.write("exit")
	findText("EXIT")
	com.cmd_on = false
end

function set(command)
	com.write(command)
	findText("AOK")
end

function save()
	com.write("save")
	findText("Storing in config")
end

function get(command, index)
	com.write(command)
	for i = 1, 100 do
		input = findText("=")					
		local indexNow, value = input:match("(.+)=(.*)")
		if index == indexNow then
			return value
		end
	end
	error("wifly returned not required index")
end
