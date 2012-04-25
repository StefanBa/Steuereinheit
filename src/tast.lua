local kit = require( "kit" )

prog = {}

function prog.run()
	if kit.IO.DIN1.merge == 1 then
		kit.IO.DOUT0.real = 1
	else
		kit.IO.DOUT0.real = 0
	end
end
