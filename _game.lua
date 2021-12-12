--[[
	Logic class for the game.
	Jason A. Petrasko (C) 2022
]]

Object = require "classic"

Game = Object:extend()

function Game:load()
end

function Game:update(dt)
end

function Game:draw()
end

function Game:setRenderer(r)
	self.artist = r
end

return Game