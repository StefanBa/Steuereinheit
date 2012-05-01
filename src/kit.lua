
local pio = pio

module(..., package.seeall)	

local pressed = {}
BTN_SELECT  = pio.PB_7
BTN_WPS 	= pio.PE_3
LED_GRUN  	= pio.PB_6
LED_ORANGE 	= pio.PB_5
CMD 		= pio.PA_7
RstWLAN 	= pio.PA_6

pio.pin.setdir( pio.INPUT, BTN_SELECT, BTN_WPS )
pio.pin.setpull( pio.PULLUP, BTN_SELECT, BTN_WPS )
pio.pin.setdir( pio.OUTPUT, LED_GRUN, LED_ORANGE, CMD, RstWLAN )


local adc_smoothing = 4
local adc_timer = 1 
local adc_f = 4
local tsample

local pwm_f = 50000

btn_pressed = function( button )
  return pio.pin.getval( button ) == 0
end

button_clicked = function( button )
  if btn_pressed( button ) then
    pressed[ button ] = true
  else
    if pressed[ button ] then
      pressed[ button ] = nil
      return true
    end
  end
  return false
end

IO = {
		DOUT0 = {adress = pio.PB_6},
		DOUT1 = {adress = pio.PB_5},
		DOUT2 = {adress = pio.PH_6},
		DOUT3 = {adress = pio.PH_7},
		DOUT4 = {adress = pio.PI_0},
		DOUT5 = {adress = pio.PI_1},
		DOUT6 = {adress = pio.PI_2},
		DOUT7 = {adress = pio.PI_3},
		DOUT8 = {adress = pio.PI_4},
		DOUT9 = {adress = pio.PI_5},

		
		DIN0 = {adress = pio.PB_7},
		DIN1 = {adress = pio.PE_3},
		
		AIN0 = {adress = 0},
		AIN1 = {adress = 1},
		AIN2 = {adress = 2},
		AIN3 = {adress = 3},
		
		AOUT0 = {adress = 0},
		AOUT1 = {adress = 1},
		AOUT2 = {adress = 2},
		AOUT3 = {adress = 3}
		}

mt = { __index = {real = 0, custom, merge = 0} }

for i, v in pairs(IO) do
	setmetatable(IO[i], mt)
end


for i in pairs(IO) do

	if i:find("DIN") then
		pio.pin.setdir( pio.INPUT, IO[i].adress )
		pio.pin.setpull( pio.PULLUP, IO[i].adress )
	
	elseif i:find("DOUT") then
		pio.pin.setdir( pio.OUTPUT, IO[i].adress )
	
	elseif i:find("AIN") then
		adc.setblocking( IO[i].adress,0) -- no blocking on any channels
 		adc.setsmoothing( IO[i].adress, adc_smoothing ) -- set smoothing from adcsmoothing table
  		adc.setclock( IO[i].adress, adc_f, adc_timer ) -- get 4 samples per second, per channel	
	
	else
		pwm.setup( IO[i].adress, pwm_f, IO[i].real )
		pwm.start( IO[i].adress )
	end
	
end

adc.sample({0,1,2,3},128)

function update()
	for i in pairs(IO) do
	
		if i:find("DIN") then
			IO[i].real = pio.pin.getval( IO[i].adress )
			
		elseif i:find("DOUT") then
			pio.pin.setval( IO[i].merge, IO[i].adress )
			
		elseif i:find("AIN") then
			if adc.isdone(IO[i].adress) == 1 then adc.sample(IO[i].adress,128) end --wenn buffer voll, neustart
			tsample = adc.getsample(IO[i].adress) --nächstes sample vom buffer holen
			if not (tsample == nil) then 
    			IO[i].real = tsample
    		end
    				
		else
			pwm.setup( IO[i].adress, pwm_f, IO[i].merge )		
		end
		
	end
end

function merge()
	for i in pairs(IO) do
		if IO[i].custom then
			IO[i].merge = IO[i].custom
		else
			IO[i].merge = IO[i].real
		end
	end
end

function reset()
	for i in pairs(IO) do
		IO[i].custom = nil
	end
end








