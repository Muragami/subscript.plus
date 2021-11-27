--[[
    The game, but nothing in here. This just puts the systems together.
    Jason A. Petrasko (c) 2022
]]

Artist = require '_render'
Game = require '_game'

-- Load some default values for our rectangle.
function love.load()
    Game:load()
    Game:setRenderer(Artist)
    Artist:load()
end

-- Increase the size of the rectangle every frame.
function love.update(dt)
    Game:update(dt)
    Artist:update(dt)
end

-- Draw a coloured rectangle.
function love.draw()
    Game:draw()
    Artist:draw()
end
