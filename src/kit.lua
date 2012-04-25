
local pio = pio

module(..., package.seeall)	

local pressed = {}
BTN_SELECT  = pio.PB_4
LED_1  = pio.PD_0

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
		DIN1 = {adress = pio.PE_7}
		}

mt = { __index = {real = 0, custom, merge = 0} }

for i, v in pairs(IO) do
	setmetatable(IO[i], mt)
	pio.pin.setdir( pio.OUTPUT, IO[i].adress )
end


for i in pairs(IO) do
	if i:find("DIN") then
		pio.pin.setdir( pio.INPUT, IO[i].adress )
		pio.pin.setpull( pio.PULLUP, IO[i].adress )
	elseif i:find("DOUT") then
		pio.pin.setdir( pio.OUTPUT, IO[i].adress )
	elseif i:find("AIN") then
	
	else
	
	end
end


function update()
	for i in pairs(IO) do
		if i:find("DIN") then
			IO[i].real = pio.pin.getval( IO[i].adress )
		elseif i:find("DOUT") then
			pio.pin.setval( IO[i].merge, IO[i].adress )
		elseif i:find("AIN") then
		
		else
		
		end
	end
end

function merge()
	for i, v in pairs(IO) do
		if IO[i].custom then
			IO[i].merge = IO[i].custom
		else
			IO[i].merge = IO[i].real
		end
	end
end

function reset()
	for i, v in pairs(IO) do
		IO[i].custom = nil
	end
end








