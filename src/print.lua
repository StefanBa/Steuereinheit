
count = 0

LED  = pio.PB_6
pio.pin.setdir( pio.OUTPUT, LED )

while true do

	pio.pin.setval( 0, LED )
	tmr.delay( 0, 100000 )
	pio.pin.setval( 1, LED )
	tmr.delay( 0, 100000 )
	

	--print("halo" .. count)
	--count = count + 1
end
