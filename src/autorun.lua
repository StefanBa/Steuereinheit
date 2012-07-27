
local showio = false
printold = print
function printnew(...)
	if not showio then
		printold(...)
	end
end
print = printnew

require "conf"
require "kit"
require "control"
require "com"
require "cmd"

term.clrscr()
print("\n\r Android-basiertes Home Automation System \n\r")

threads = {}
threadstart = 1
threadend = 2

--thread1: init
table.insert(threads, coroutine.create(function ()
	com.init()
	conf.init()
	control.init()
	threadstart = 2
	threadend = 4
end))

--thread2: com
table.insert(threads, coroutine.create(function ()
	while true do
		com.run()
		coroutine.yield()
	end
end))

--thread3: control
table.insert(threads, coroutine.create(function ()
	while true do
		control.run()
		coroutine.yield()
	end
end))

--thread4: kit
table.insert(threads, coroutine.create(function ()
	while true do
		kit.run()
		coroutine.yield()
	end
end))

local ram, rammax = 0, 0
local tstart = tmr.start(3)	--für ramcollectblabla

while true do
	local state, msg
	for i = threadstart, threadend do
		state, msg = coroutine.resume(threads[i])
		if not state then
			print("error message:",msg)
			break
		end
	end
	
	if not state then break end
	
	key = term.getchar( term.NOWAIT )
  	if key == term.KC_ESC then break end -- exit if user hits Escape
	
--[[
	if kit.button_clicked(kit.BTN_WPS) then
		if showio then
			showio = false
			term.clrscr()
			term.moveto(1,1)
		else
			showio = true
			term.clrscr()
		end			
	end
	
	if showio then
		local line = 1
		term.print( 1, line, "ID real custom merge adress\n")
		for _,i in pairs(kit.SORT) do
			line = line + 1
			local merge = kit.IO[i].merge
			local custom = kit.IO[i].custom
			if (kit.IO[i].custom == nil) then custom = 9999 end
			if (kit.IO[i].merge == nil) then merge = 9999 end
			term.print( 1, line, i, string.format(" %4d %4d %4d %4d\n", kit.IO[i].real, custom, merge, kit.IO[i].adress ) )
		end
	end
--]]

--[[
	ram = collectgarbage'count'		--

	if ( tmr.getdiffnow( 3, tstart ) > 200000 ) then
		print(ram)
		tstart = tmr.start(3)
	end
--]]
end




