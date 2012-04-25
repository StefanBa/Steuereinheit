require "kit"
require "control"
require "com"

threads = {}

table.insert(threads, coroutine.create(function ()
	while true do
		control.run()
		coroutine.yield()
	end
end))

table.insert(threads, coroutine.create(function ()
	while true do
		com.run()
		coroutine.yield()
	end
end))

dofile("/rom/prog.lc")

com.init()

--term.clrscr()


while true do
	local state, msg
	
	for i=1, control.threadend do
		state, msg = coroutine.resume(threads[i])
		if not state then
			print(msg)
			break
		end
	end
	
	kit.merge()
	kit.update()
	
	term.print(1,2,string.format("ADC%02d : %04d\n", kit.IO.AIN0.adress, kit.IO.AIN0.real))
	term.print(1,3,string.format("ADC%02d : %04d\n", kit.IO.AIN1.adress, kit.IO.AIN1.real))
	term.print(1,4,string.format("ADC%02d : %04d\n", kit.IO.AIN2.adress, kit.IO.AIN2.real))
	term.print(1,5,string.format("ADC%02d : %04d\n", kit.IO.AIN3.adress, kit.IO.AIN3.real))

	if not state then break end
end


