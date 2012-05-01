
IO = {
	
		AIN0 = {adress = 0},
		AIN1 = {adress = 1},
		AIN2 = {adress = 2},
		AIN3 = {adress = 3}
		}


adcchannels = {0,1,2,3}


local adc_smoothing = 4
local adc_timer = 1 
local adc_f = 4
local tsample


for i in pairs(IO) do
  adc.setblocking(IO[i].adress,0) 
  adc.setsmoothing(IO[i].adress,adc_smoothing) 
  adc.setclock(IO[i].adress, adc_f ,adc_timer)
end


term.clrscr()

adc.sample({0,1,2,3},128)

while true do
  for i in pairs(IO) do

    if adc.isdone(IO[i].adress) == 1 then adc.sample(IO[i].adress,128) end 

    tsample = adc.getsample(IO[i].adress)

    if not (tsample == nil) then 
    	term.print(1,IO[i].adress+2,string.format("ADC%02d : %04d\n", IO[i].adress, tsample))
    end
  end
end
