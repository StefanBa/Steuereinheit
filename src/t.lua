
module(..., package.seeall)

function year()					-- four digits
	return os.date("*t").year	
end

function month()				-- 1--12
	return os.date("*t").month	
end

function day()					-- 1--31
	return os.date("*t").day	
end

function hour()					-- 0--23
	return os.date("*t").hour		
end

function min()					-- 0--59
	return os.date("*t").min	
end

function sec()					-- 0--61
	return os.date("*t").sec
end

function wday()					-- weekday, Sunday is 1
	return os.date("*t").wday
end

function yday()					-- day of the year
	return os.date("*t").yday
end

function isdst()				-- daylight saving flag, a boolean
	return os.date("*t").isdst
end

