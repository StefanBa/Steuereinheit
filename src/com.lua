local kit = require( "kit" )
local list = require("list")

module(..., package.seeall)

local id = 0
local sendList = list.List:new()
local recvList = list.List:new()
--local connected = false
local connected = true
local END = "\r"


local baudhw = uart.setup(id, 9600, 8, uart.PAR_NONE, uart.STOP_1 )
uart.set_buffer( id, 256 )

local function checkconnect(input)
	if input:find("*OPEN*") then
		if not connected then print("connected") end
		connected = true
	elseif input:find("*CLOS*") then
		if connected then print("disconnected") end
		connected = false
	end
end


function write(s)
	sendList:pushfirst(s)
end

function read()
	return recvList:poplast()
end

function send()
	local output = sendList:poplast()
	if output == nil then return end
	uart.write( id, output)
	print( "sent:    " , output )
end

function recv()
	local input, data
	
	input = uart.read( id, '*l', uart.NO_TIMEOUT)
	if input == "" then return end
	local tstart = tmr.start( 0 )
	
	while input:sub(-1,-1) ~= END do
		data = uart.read( id, '*l', uart.NO_TIMEOUT)
		input = input .. data
		
		checkconnect(input)
		
		local tend = tmr.read( 0 )
		--local delta = tmr.gettimediff( 0, tstart, tend )
		local delta = tmr.gettimediff( 0, tend, tstart )
		if delta > (200000) then
			print("timeout: " , input)
			input = ""
			break
		end
		
		coroutine.yield()					  	
	end
	
	checkconnect(input)
	
	input = input:sub(1,-2)                     --\r abschneiden
	if connected then
		print( "received:" , input )
		recvList:pushfirst( input )
	end
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
end --]]









