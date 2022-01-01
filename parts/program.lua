--[[
	General (not specific) logic for the game, running in strands.

	A program is a strand that is configured to work as a single part of the game (async).
	
	Jason A. Petrasko (C) 2022
]]

local Object = require "classic"

Program = Strand:extend()

