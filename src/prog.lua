local kit = require( pd.board() )
local state = false
local tstart = tmr.start( 3 )	

prog = {}

function prog.run()
	local tend = tmr.read( 3 )
	local delta = tmr.gettimediff( 3, tstart, tend )
	if delta > (400000) then
		if state then
	  		pio.pin.sethigh( kit.LED_1 )
	  		state = false
	  	else
	  		pio.pin.setlow( kit.LED_1 )
	  		state = true
	  	end
	    tstart = tmr.start( 3 )
	end	
end






