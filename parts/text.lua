--[[
	Text visuals for the game.
	Jason A. Petrasko (C) 2022
]]

-- discover all loadable fonts and put their names into a table
local function starts_with(str, start)
   return str:sub(1, #start) == start
end

local function ends_with(str, ending)
   return ending == "" or str:sub(-#ending) == ending
end

local function buildFontTable()
	local files = love.filesystem.getDirectoryItems("img/")
	local ret = {}
	for k, file in ipairs(files) do
		if ends_with(file,".fnt.lua") then
			ret[file] = true
		end
	end
	return ret
end

fntFiles = buildFontTable()

Object = require "classic"

Font = Object:extend()

function Font:new(str)
	-- see if the font exists and if it does, load it!
	if fntFiles[str .. ".fnt.lua"] then

	else
		error("The font '" .. str .. "' not found!")
	end
end

Text = Object:extend()



