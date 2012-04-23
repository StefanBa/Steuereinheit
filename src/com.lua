local kit = require( pd.board() )
local list = require("list")
local uart = uart
local print = print
local tmr = tmr
local coroutine = coroutine
local io = io

module(...)

local id = 1
local sendList = list.List:new()
local recvList = list.List:new()
local connected = false

function init ()
	local baudhw = uart.setup(id, 9600, 8, uart.PAR_NONE, uart.STOP_1 )
	uart.set_buffer( id, 256 )
end

function write(s)
	sendList:pushfirst(s)
end

function read()
	return recvList:poplast()
end

function send()
	local s = sendList:poplast()
	if s == nil then return end
	uart.write( id, s)
	print("send: "..s)
end

function recv()
	local input, data
	input = uart.read( id, '*l', uart.NO_TIMEOUT)
	if input == "" then return end
	local tstart = tmr.start( 0 )	
	while input:sub(-1,-1) ~= "\r" do
		data = uart.read( id, '*l', uart.NO_TIMEOUT)
		input = input .. data
		if input:find("*OPEN*") then connected = true end
		if input:find("*CLOS*") then connected = false end	
		local tend = tmr.read( 0 )
		local delta = tmr.gettimediff( 0, tstart, tend )
		if delta > (100000) then
			print("TIMEOUT: string wird verworfen:" .. input)
			input = ""
			break
		end
		coroutine.yield()					  	
	end
	input = input:sub(1,-2)                     --\r abschneiden
	if connected then
		recvList:pushfirst(input)
		print("from com " .. input)
	end
end

function run()
	recv()
	send()
	test()
end

function test()
	local prot
	if kit.button_clicked( kit.BTN_SELECT ) then
		print("protocol input:")
		prot = io.read()
		recvList:pushfirst(prot)
	elseif kit.button_clicked( kit.BTN_DOWN ) then
		print("sendlist lenght: "..#recvList)
	end
end






