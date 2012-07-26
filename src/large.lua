
print("hello from large.lua")


t = {}


for i=1, math.huge do
	table.insert(t,"blabliblu")
	print(collectgarbage'count')
end


