--[[
	level/boot kickstarts the entire game
	Jason A. Petrasko (C) 2022
]]

-- load the local level program, this is boot, so it is loaded before anything else
bootProg = Program.load("boot")

-- start us up!
bootProg:init()
