
module(..., package.seeall)	

List = {first = 0, last = -1}

function List:new(l)
	l = l or {}
	setmetatable(l,self)
	self.__index = self
return l
end

function List:pushfirst(value)
	local first = self.first-1
	self.first = first
	self[first] = value
end

function List:poplast()
	local last = self.last
	if self.first > last then return nil end --list is empty
	local value = self[last]
	self[last] = nil
	self.last = last - 1
	return value
end