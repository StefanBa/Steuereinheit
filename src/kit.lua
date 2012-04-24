
local pio = pio

module(..., package.seeall)	

local pressed = {}

BTN_SELECT  = pio.PB_4
LED_1  = pio.PD_0

pio.pin.setdir( pio.INPUT, BTN_SELECT )
pio.pin.setpull( pio.PULLUP, BTN_SELECT )
pio.pin.setdir( pio.OUTPUT, LED_1 )


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

d_out = {
		DOUT0 = {adress = pio.PD_0},
		DOUT1 = {adress = pio.PH_1},
		DOUT2 = {adress = pio.PH_2},
		DOUT3 = {adress = pio.PH_3},
		DOUT4 = {adress = pio.PH_4}
		}

mt = { __index = {real = 0, custom, merge = 0} }

for i, v in pairs(d_out) do
	setmetatable(d_out[i], mt)
	pio.pin.setdir( pio.OUTPUT, d_out[i].adress )
end

function update()
	for i in pairs(d_out) do
		pio.pin.setval( d_out[i].merge, d_out[i].adress )
	end
end

function merge()
	for i, v in pairs(d_out) do
		if d_out[i].custom then
			d_out[i].merge = d_out[i].custom
		else
			d_out[i].merge = d_out[i].real
		end
	end
end

function reset()
	for i, v in pairs(d_out) do
		d_out[i].custom = nil
	end
end








