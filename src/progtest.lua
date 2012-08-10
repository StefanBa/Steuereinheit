-------------------------------------------------------------------------------
-- FHNW			Studiengang EIT
-- Projekt6		Android-basiertes Home Automation System
-- Web			http://web.fhnw.ch/technik/projekte/eit/Fruehling2012/BaumKell/
-- @author		Stefan Baumann, stefan.baumann1@students.fhnw.ch
-- @release		Datum: 17.08.2012
-- @description	Testprogramm, "Verbindet" die Eingänge mit den Ausgängen um sie
--				testen zu können
-------------------------------------------------------------------------------

module(..., package.seeall)

require "kit"

table.insert(threads, coroutine.create(function ()
t = {}
	while true do
		for i in pairs(kit.IO) do	
			if i:find("DO") then
				local IN = i:gsub("O","I")
				kit.IO[i].real = kit.IO[IN].merge
			elseif i:find("AO") then
				local IN = i:gsub("O","I")
				kit.IO[i].real = math.ceil(99/4095 * kit.IO[IN].merge)
			end
		end
		coroutine.yield()
	end
	
end))

PROGCOMPLETE = true
