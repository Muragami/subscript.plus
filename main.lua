--[[
    The game, but nothing in here. This just puts the systems together.
    Jason A. Petrasko (c) 2022
]]

Artist = require '_render'
Game = require '_game'

local theGame = Game()
local theArtist = Artist()

function love.load()
    theGame:load()
    theGame:setRenderer(theArtist)
    theArtist:load()
end

function love.update(dt)
    theGame:update(dt)
    theArtist:update(dt)
end

function love.draw()
    theGame:draw()
    theArtist:draw()
end
