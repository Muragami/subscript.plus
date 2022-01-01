--[[
	Logic class for the game.
	Jason A. Petrasko (C) 2022
]]

Object = require "classic"

require "parts/gload"

Game = Object:extend()

function Game:load()
end

function Game:update(dt)
	self.artist:update(dt)
end

function Game:draw()
end

function Game:setRenderer(r)
	self.artist = r
end

return Game