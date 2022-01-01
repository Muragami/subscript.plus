--[[
    The game, but nothing in here. This just puts the systems together.
    Jason A. Petrasko (c) 2022
]]

io.stdout:setvbuf("no")

-- top level object collection
TLOC = {}

-- include some core stuff
require 'strand'

-- we just need an Artist and a Game to get it all going!
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
    -- inform all the top level objects
    for _, obj in pairs(TLOC) do
        if obj.update then obj.update(dt) end
    end

    -- strands gotta dance
    strandUpdate(dt)

    -- update the game
    theGame:update(dt)

    -- Make sure no thread errors occured, and if so, pass them out as full errors!
    strandCheckErrors()
end

function love.draw()
    theArtist:draw()
end
