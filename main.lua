--[[
    The game, but nothing in here. This just puts the systems together.
    Jason A. Petrasko (c) 2022
]]

-- let the output show in sublime text editor
io.stdout:setvbuf("no")

inspect = require("debug.inspect")
DEBUG = true

-- top level object collection
TLOC = {}
-- top level callback listeners
TLCLC = { displayrotated = {}, errorhandler = {}, lowmemory = {}, quit = {},
    threaderror = {}, directorydropped = {}, filedropped = {}, focus = {},
    mousefocus = {}, resize = {}, visible = {}, keypressed = {}, keyreleased = {},
    textedited = {}, textinput = {}, mousemoved = {}, mousepressed = {},
    mousereleased = {}, wheelmoved = {}, gamepadaxis = {}, gamepadpressed = {},
    gamepadreleased = {}, joystickadded = {}, joystickaxis = {}, joystickhat = {},
    joystickpressed = {}, joystickreleased = {}, joystickremoved = {} }

-- include some core stuff
require 'strand'

-- some functions to manage the top level state
function callTop(func,x)
    for k, obj in pairs(TLOC) do
        local f = obj[func]
        if f then f(obj,x) end
    end
end

function sendTop(to_name,from_name,x)
    local o = TLOC[name]
    if o then
        o.chan:push({from_name, x})
    end
end

function makeTopObject(name,x)
    x.tl_name = name
    x.top = true
    x.chan = chanTable[name]
    x.send = function(self,obj,x)
        sendTop(self.tl_name,obj,x)
    end
    x.msg = function(self)
        return self.chan:pop()
    end
end
function unmakeTopObject(name)
    local x = TLOC[name]
    x.top = false
    x.chan = nil
    x.send = nil
    TLOC[name] = nil
end
function addTopObject(name,x) makeTopObject(name,x) TLOC[name] = x end
function delTopObject(name) unmakeTopObject(name) end


-- we just need an Artist and a Game to get it all going!
Artist = require '_render'

-- load the game!
require "parts/gload"

local theArtist = Artist()

function love.load()
    theArtist:load()
    TLOC['/RENDERER'] = theArtist
end

function love.update(dt)
    -- inform all the top level objects
    callTop('update',{ dt })

    -- strands gotta dance
    strandUpdate(dt)
end

function love.draw()
    TLOC['/RENDERER']:draw()
end

function callTopLevelCallback(str,vtab)
    if str == 'quit' then
        local ret = false
        for k, v in pairs(TLCLC[str]) do
            local f = v[str]
            if f then 
                if f(v,str,vtab) then ret = true end
            end
        end
        return ret
    else
        for k, v in pairs(TLCLC[str]) do
            local f = v[str]
            if f then f(v,str,vtab) end
        end 
    end
end

function addTopLevelCallback(name,x)
    TLCLC[name] = x
end

function delTopLevelCallback(name)
    TLCLC[name] = nil
end

function love.displayrotated(index, orientation) callTopLevelCallback('displayrotated', { index, orientation } ) end
--function love.errorhandler(msg) callTopLevelCallback('errorhandler', { msg } ) end
function love.lowmemory() callTopLevelCallback('lowmemory', {} ) end
function love.quit() return callTopLevelCallback('quit', {} ) end
function love.threaderror(thread, msg)
    if DEBUG then print("threaderror [" .. tostring(thread) .. "] " .. msg) end
    callTopLevelCallback('threaderror', { thread, msg } ) 
end
function love.directorydropped(path) callTopLevelCallback('directorydropped', { path } ) end
function love.filedropped(path) callTopLevelCallback('filedropped', { path } ) end
function love.focus(x) callTopLevelCallback('focus', { x } ) end
function love.mousefocus(x) callTopLevelCallback('mousefocus', { x } ) end
function love.resize(w,h) callTopLevelCallback('resize', { w,h } ) end
function love.visible(x) callTopLevelCallback('visible', { x } ) end
function love.keypressed(k,s,rep) callTopLevelCallback('keypressed', { k, s, rep } ) end
function love.keyreleased(k,s) callTopLevelCallback('keyreleased', { k, s } ) end
function love.textedited(t,s,l) callTopLevelCallback('textedited', { t, s, l } ) end
function love.textinput(t) callTopLevelCallback('textinput', { t } ) end
function love.mousemoved(x,y,dx,dy,i) callTopLevelCallback('mousemoved', { x, y, dx, dy, i } ) end
function love.mousepressed(x,y,b,i,p) callTopLevelCallback('mousepressed', { x, y, b, i, p } ) end
function love.mousereleased(x,y,b,i,p) callTopLevelCallback('mousereleased', { x, y, b, i, p } ) end
function love.wheelmoved(x,y) callTopLevelCallback('wheelmoved', { x, y } ) end
function love.gamepadaxis(j,a,v) callTopLevelCallback('gamepadaxis', { j, a, v } ) end
function love.gamepadpressed(j,b) callTopLevelCallback('gamepadpressed', { j, b } ) end
function love.gamepadreleased(j,b) callTopLevelCallback('gamepadreleased', { j, b } ) end
function love.joystickadded(x) callTopLevelCallback('joystickadded', { x } ) end
function love.joystickaxis(j,a,v) callTopLevelCallback('joystickaxis', { j, a, v } ) end
function love.joystickhat(j,h,v) callTopLevelCallback('joystickhat', { j, h, v } ) end
function love.joystickpressed(j,b) callTopLevelCallback('joystickpressed', { j, b } ) end
function love.joystickreleased(j,b) callTopLevelCallback('joystickreleased', { j, b } ) end
function love.joystickremoved(x) callTopLevelCallback('joystickremoved', { x } ) end

