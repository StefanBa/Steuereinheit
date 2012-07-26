
module(..., package.seeall)

require "kit"
require "list"

uart_id = 0
status = "normal"					--status kann sein: "normal", "cmd", file

local sendList = list.List:new()
local recvList = list.List:new()
local connected = true				--init-Wert default: false (zu Debugzwecken: true)
local END1 = "\r"
local END2 = "\n"
local SEP = ";"
local timer_id = 1

function init()
	local baudhw = uart.setup(uart_id, 9600, 8, uart.PAR_NONE, uart.STOP_1 )
	uart.set_buffer( uart_id, 256 )
end

function checkconnect(input)
	if input:find("*OPEN*") then
		if not connected then print("connected") end
		connected = true
	elseif input:find("*CLOS*") then
		if connected then print("disconnected") end
		connected = false
	end
end

function write(s,...)
	local arg = {...}
	for _, i in pairs(arg) do
		if type(i) == "number" then i = tostring(i) end
		s = s .. SEP .. i
	end
	if status == "cmd" then
		sendList:pushfirst(s .. END1)
		return
	end
	sendList:pushfirst(s .. END1 .. END2)
end

function read()
	local recv = recvList:poplast()
	if recv == nil then return recv end
	
	if status == "cmd" then
		return recv
	end
	
	local splitter = {}
	for k in recv:gmatch("[^%"..SEP.."]+") do
		splitter[#splitter + 1] = k
	end
	return splitter
end

function send()
	local output = sendList:poplast()
	if output == nil then return end
	uart.write( uart_id, output)
	print( "sent:    " , output:sub(1,-2) )
end

function recv()
	local input, data
	input = uart.read( uart_id, '*l', uart.NO_TIMEOUT)
	if input == "" then return end
	local tstart = tmr.start( timer_id )
	
	while input:sub(-1,-1) ~= END1 do
		data = uart.read( uart_id, '*l', uart.NO_TIMEOUT)
		input = input .. data
		checkconnect(input)
		local delta = tmr.getdiffnow( timer_id, tstart )
		if delta > (200000) then
			print("timeout: " , input)
			input = ""
			return
		end
		coroutine.yield()					  	
	end
	
	if status == "cmd" then								--falls WLAN-Modul im cmd-Mode
		print( "cmd received:", input )
		recvList:pushfirst( input )
		return
	end
	
	if not connected then
		print( "not received:" , input)
		return
	end
	
	--if status == "file" then end
	
	input = input:sub(1,-2)                     --\r abschneiden
	print( "received:" , input )
	recvList:pushfirst( input )

end

function run()
	recv()
	send()
--	test()
end

--[[
function test()
	local prot
	if kit.button_clicked( kit.BTN_SELECT ) then
		print("protocol input:")
		prot = io.read()
		recvList:pushfirst(prot)
	end
--	elseif kit.button_clicked( kit.BTN_DOWN ) then
--		print("sendlist lenght: "..#recvList)
--	end
end
--]]








