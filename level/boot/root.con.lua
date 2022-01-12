--[[
	Root controller program. End Of Line.
]]

-- the array that defines this thread that we will return
local prg = { func = {} }

-- *********************************************************
-- CONFIG
prg.conf = {
	static = true, 				-- never unload this thread
	name = "I2007", 			-- unique thread name inside this progam
	addr = "127.000.000.001", 	-- an address for this thread
	init = true, 				-- if true, we start when program:init() is called (otherwise we start on demand)
	lead = true, 				-- if true, the lead controller of the program
	-- what protocols for messages do we accept
	protocol = { CMD_LINE = 1.0 },
	-- are we listening for any callbacks?
	callbacks = { }
}

-- *********************************************************
-- load function, called at thread start
prg.load = function()
end

-- *********************************************************
-- FUNCTIONS
prg.func['`'] = function(self,tname,cmd,tab)

end

-- the prophecy is fulfilled!
return prg