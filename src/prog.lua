local kit = require( "kit" )

local function mydelay(t)
	local tstart = tmr.start( 3 )
	local delta = 0
	
	while delta < t do
		coroutine.yield()
		local tend = tmr.read( 3 )
		delta = tmr.gettimediff( 3, tend, tstart )
	end
end

--[[
table.insert(threads, coroutine.create(function ()
	local state = false
	local tstart = tmr.start( 3 )
	local time = 400000	

	while true do
		local tend = tmr.read( 3 )
		--local delta = tmr.gettimediff( 3, tstart, tend )
		local delta = tmr.gettimediff( 3, tend, tstart )
	    --print("start: "..tstart ,"end: "..tend ,"delta: "..delta)
		if delta < (85899345-time) then
			if state and kit.IO.DIN1.merge == 1 then
		  		kit.IO.DOUT0.real = 1
		  		state = false
		  	else
		  		kit.IO.DOUT0.real = 0
		  		state = true
		  	end
		    tstart = tmr.start( 3 )
		end	
		coroutine.yield()
	end
end))


table.insert(threads, coroutine.create(function ()
	while true do	
		--kit.IO.AOUT0.real = math.ceil(99/1023 * kit.IO.AIN0.merge)
		kit.IO.DOUT0.real = kit.IO.DIN0.merge
		coroutine.yield()
	end
end))

]]--
table.insert(threads, coroutine.create(function ()
	while true do
		for i in pairs(kit.IO) do	
			if i:find("DO") then
				local IN = i:gsub("O","I")
				kit.IO[i].real = kit.IO[IN].merge
			elseif i:find("AO") then
				local IN = i:gsub("O","I")
				kit.IO[i].real = math.ceil(99/1023 * kit.IO[IN].merge)
			end
		end
		coroutine.yield()
	end
end))



--Output checks (blinky)
--[[
table.insert(threads, coroutine.create(function ()
	local time = 400000

	while true do
		for _,i in pairs(kit.SORT) do
			if i:find("DO") then
				kit.IO[i].real = 1
				mydelay(time)
				kit.IO[i].real = 0
				mydelay(time)
			elseif i:find("AO") then
				kit.IO[i].real = 99
				mydelay(time)
				kit.IO[i].real = 0
				mydelay(time)
			end
		end
		
	end
end))
--]]



