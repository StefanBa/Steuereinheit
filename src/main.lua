
require "control"
require "com"
dofile("/rom/prog.lc")

local threads = {}

threads[1] = coroutine.create(function ()
	while true do
		control.run()
--		print("thread1")
		coroutine.yield()
	end
end)

threads[2] = coroutine.create(function ()
	while true do
		com.run()
--		print("thread2")
		coroutine.yield()
	end
end)

threads[3] = coroutine.create(function ()
	while true do
		prog.run()
--		print("thread3")
		coroutine.yield()
	end
end)

com.init()

while true do
	local state, msg
	
	for i=1,#threads do
		state, msg = coroutine.resume(threads[i])
		if not state then
			print(msg)
			break
		end
	end
	
	kit.merge()
	kit.update()
	
	if not state then break end
end



