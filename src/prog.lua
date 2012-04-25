local kit = require( "kit" )

table.insert(threads, coroutine.create(function ()
	local state = false
	local tstart = tmr.start( 3 )
	local time = 400000	

	while true do
		local tend = tmr.read( 3 )
		local delta = tmr.gettimediff( 3, tstart, tend )
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


