
module(..., package.seeall)

require "conf"

local pressed = {}
local t_update = {}

BTN_WPS 	= pio.PE_2
pio.pin.setdir( pio.INPUT, BTN_WPS )
pio.pin.setpull( pio.PULLUP, BTN_WPS )

local adc_smoothing = 4
local adc_timer = 3 
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
		DO0 = {adress = pio.PB_4},
		DO1 = {adress = pio.PB_5},
		DO2 = {adress = pio.PB_6},
		DO3 = {adress = pio.PB_7},
		DO4 = {adress = pio.PA_6},
		DO5 = {adress = pio.PA_7},
		DO6 = {adress = pio.PF_0},
		DO7 = {adress = pio.PH_7},
	
		DI0 = {adress = pio.PD_7},
		DI1 = {adress = pio.PD_6},
		DI2 = {adress = pio.PD_5},
		DI3 = {adress = pio.PD_4},
		DI4 = {adress = pio.PF_3},
		DI5 = {adress = pio.PF_2},
		DI6 = {adress = pio.PF_1},
		DI7 = {adress = pio.PH_6},
				
		AI0 = {adress = 0},
		AI1 = {adress = 3},
		AI2 = {adress = 1},
		AI3 = {adress = 2},
		
		AO0 = {adress = 2},
		AO1 = {adress = 3},
		AO2 = {adress = 0},
		AO3 = {adress = 1}
	}

SORT = {}
for n in pairs(IO) do SORT[#SORT + 1] = n end
table.sort(SORT)

mt = { __index = {real = 0, custom, merge = 0} }

for i, v in pairs(IO) do
	setmetatable(IO[i], mt)
end

for i in pairs(IO) do
	if i:find("DI") then
		pio.pin.setdir( pio.INPUT, IO[i].adress )
		pio.pin.setpull( pio.PULLUP, IO[i].adress )
	
	elseif i:find("DO") then
		pio.pin.setdir( pio.OUTPUT, IO[i].adress )
	
	elseif i:find("AI") then
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
	for _,i in pairs(conf.get("update", "*t")) do
		if i:find("DI") then
			IO[i].real = pio.pin.getval( IO[i].adress )
			
		elseif i:find("DO") then
			pio.pin.setval( IO[i].merge, IO[i].adress )
			
		elseif i:find("AI") then
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

local function merge()
	for _,i in pairs(conf.get("update", "*t")) do
		if IO[i].custom then
			IO[i].merge = IO[i].custom
		else
			IO[i].merge = IO[i].real
		end
	end
end

function reset(key)			--beim Program aus / ändern von _G.const.update
	local value = 0
	if key == "custom" then value = nil end
	for i in pairs(IO) do
		IO[i][key] = value
	end
end

function run()
	merge()
	update()
end








