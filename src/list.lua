-------------------------------------------------------------------------------
-- FHNW			Studiengang EIT
-- Projekt6		Android-basiertes Home Automation System
-- Web			http://web.fhnw.ch/technik/projekte/eit/Fruehling2012/BaumKell/
-- @author		Stefan Baumann, stefan.baumann1@students.fhnw.ch
-- @release		Datum: 17.08.2012
-- @description	Eine Liste, die mit push und pop gefüllt/geleert werden kann. 
--				Ist eine Klasse und kann mehrfach instanziert werden.
--				Das Funktionsprinzip wurde vom Buch "Programmieren mit LUA"
--				übernommen.
-------------------------------------------------------------------------------

module(..., package.seeall)	

List = {first = 0, last = -1}

-------------------------------------------------------------------------------
-- Generiert neue Liste.
-- @param	l ist optional, falls eine bestehende Liste verwendet werden möchte
-- @return 	l die Liste, welch nun mit push/pop verwendet werden kann

function List:new(l)
	l = l or {}
	setmetatable(l,self)
	self.__index = self
return l
end

-------------------------------------------------------------------------------
-- Fügt neues Element hinzu.
-- @param	value ist das neue Element

function List:pushfirst(value)
	local first = self.first-1
	self.first = first
	self[first] = value
end

-------------------------------------------------------------------------------
-- Gibt letztes Element zurück.
-- @param	value ist das neue Element

function List:poplast()
	local last = self.last
	if self.first > last then return nil end --list is empty
	local value = self[last]
	self[last] = nil
	self.last = last - 1
	return value
end