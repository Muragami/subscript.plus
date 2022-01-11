--[[
	Messaging for threads in Love2d.
	Jason A. Petrasko (C) 2022
	< MIT License, https://opensource.org/licenses/MIT >

	strand.default.lua is the default thread routine.
	In this routine, you can program commands into the thread,
	and these will be called when you message the thread.
	You may also install two special commands:
		'`': a tick command, executed each tick of the thread (20 MS or faster)
		'!': a bang command, executed when the thread is released (ended)
]]

_name = ...
require 'strand_thread'
require 'love.timer'

local function tick(thread, dt)
	if thread.valid and thread.command['`'] then 
		thread.command['`'](thread,thread.name,'`', { [1] = dt })
	end
end

while thread.valid do
	-- the loop!
	ref = love.timer.getTime()
	local msg = thread:waitMsg(0.02) -- wait 20 MS
	if msg then
		thread:exec(msg)
	end
	tick(thread, love.timer.getTime() - ref)
end

-- report back to root we ended
thread.root:push({ thread.name, '&&', nil })
