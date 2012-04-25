
local pio = pio

module(..., package.seeall)	

local pressed = {}
BTN_SELECT  = pio.PB_4
LED_1  = pio.PD_0

local adc_smoothing = 4
local adc_timer = 1 
local adc_f = 4
local tsample

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
		DOUT0 = {adress = pio.PD_0},
		DOUT1 = {adress = pio.PH_1},
		DOUT2 = {adress = pio.PH_2},
		DOUT3 = {adress = pio.PH_3},
		DOUT4 = {adress = pio.PH_4},
		
		DIN0 = {adress = pio.PB_4},
		--DIN1 = {adress = pio.PE_7},   --ADCPort!
		
		AIN0 = {adress = 0},
		AIN1 = {adress = 1},
		AIN2 = {adress = 2},
		AIN3 = {adress = 3},
		
		AOUT0 = {adress = pio.PD_0},
		AOUT1 = {adress = pio.PD_1},
		AOUT2 = {adress = pio.PD_2},
		AOUT3 = {adress = pio.PD_3}
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
		adc.setblocking(IO[i].adress,0) -- no blocking on any channels
 		adc.setsmoothing(IO[i].adress,adc_smoothing) -- set smoothing from adcsmoothing table
  		adc.setclock(IO[i].adress, adc_f , adc_timer) -- get 4 samples per second, per channel	
	else
	
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








