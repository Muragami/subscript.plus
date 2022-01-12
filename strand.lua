--[[
	Strands, a messaging system for threads in Love2d.
	Jason A. Petrasko (C) 2022
	< MIT License, https://opensource.org/licenses/MIT >
]]

local default_thread = [[
_name, loadstr = ...

require 'love.timer'

-- *****************************************************
-- chanTable, a top level table that caches thread channels
chanTable = setmetatable( {}, {
	__index = function (table, key)
		local v = love.thread.getChannel(key)
  		rawset(table, key, v)
  		return v
	end } )

-- *****************************************************
-- thread functions!
thread = {
	name = _name,
	reference = false,
	valid = true,
	hold = 1,
	chan = chanTable[_name],
	root = chanTable['/'],
	send = {},
	command = {},
	var = {}
}

function thread:sendRoot(tab)
	self.root:push(tab)
end

function thread:sendTo(name,tab)
	chanTable[name]:push(tab)
end

function thread:send(tab)
	local i = 1
	while self.send[i] do
		self.send[i]:push(tab)
		i = i + 1
	end
end

function thread:connect(name)
	table.insert(self.send,chanTable[name])
end

function thread:disconnect(name)
	local x = chanTable[name]
	local i = 1
	local found = false
	while self.send[i] do
		if self.send[i] == x then
			found = true
			break
		end
		i = i + 1
	end
	if found then
		table.remove(self.send,i)
	end
end

function thread:sendRootMsg(cmd, var)
	self.root:push({ self.name, cmd, var })
end

function thread:sendMsg(cmd, var)
	local msg = { self.name, cmd, var }
	local i = 1
	while self.send[i] do
		self.send[i]:push(msg)
		i = i + 1
	end
end

function thread:sendMsgTo(target, cmd, var)
	chanTable[target]:push({ self.name, cmd, var })
end

function thread:waitMsg(timeout)
	return self.chan:demand(timeout)
end

function thread:setCmdFunc(cmd, func)
	local t = type(func)
	if t == 'string' then
		self.command[cmd] = loadstring(func)
	else
		error ("Bad call to thread:setCmdFunc(), func param must be a string!")
	end
end

function thread:unsetCmdFunc(cmd)
	self.command[cmd] = nil
end

function thread:unsetCmds()
	self.command = {}
end

function thread:exec(tab)
	local name = tab[1]
	local cmd = tab[2]
	local var = tab[3]
	local f = self.command[cmd]
	if f then
		local ret = f(self,name,cmd,var)
		if ret then
			self:sendTo(name, { [1] = self.name, [2] = "~", ret })
		end
	end
end

thread.command['+'] = function(thread, name, cmd, var) thread:setCmdFunc(var[1], var[2]) end
thread.command['-'] = function(thread, name, cmd, var) thread:unsetCmdFunc(var[1]) end
thread.command['|'] = function(thread, name, cmd, var) thread:unsetCmds() end
thread.command['&'] = function(thread, name, cmd, var)
	thread.valid = false
	if thread.command['!'] then	thread.command['!'](thread,name,'!',{})	end
end
thread.command['*'] = function(thread, name, cmd, var)
	for k, v in pairs(var) do thread.var[k] = v end
end

if loadstr then 
	assert(loadstring(loadstr))(_name)
end

-- *****************************************************
-- the thread itself
local function tick(thread, dt)
	if thread.valid and thread.command['`'] then
		thread.command['`'](thread, thread.name, '`', { dt })
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
]]


local Object = require "classic"

-- chanTable, a top level table that caches thread channels
chanTable = setmetatable( {}, {
	__index = function (table, key)
		local v = love.thread.getChannel(key)
  		rawset(table, key, v)
  		return v
	end } )

-- TLSC, a top level table that holds reference to all strands
TLSC = {}
TLLSC = {}	-- local strands (need special processing)

-- VarMap, a top level table of global variables to sync to all strands
strandVarMap = { frame = 0, clock = 0 }

Strand = Object:extend()

function Strand:new(name,islocal,onload_string)
	-- create a new strand with the name 'name', or make a reference to a strand with that name (if it already exists)
	if TLSC[name] then
		-- make this a reference to that strand
		self.reference = true
		self.refTarget = TLSC[name]
		self.refTarget.hold = self.refTarget.hold + 1
	else
		-- make a new strand
		self.reference = false
		self.valid = true
		self.hold = 1
		self.chan = chanTable[name]
		self.root = chanTable['/']
		self.send = {}
		self.command = {}
		self.name = name
		TLSC[name] = self
		if islocal then
			TLLSC[name] = self
			self.islocal = true
		end
		self.onload = onload_string
		self:start(islocal)
	end
end

function Strand:release()
	if self.reference then
		-- let it go!
		self.refTarget:release()
		self.reference = false
		self.refTarget = nil
	else
		-- ok, see if it's time to die or not
		self.hold = self.hold - 1
		if self.hold < 1 then
			-- we are gone, so vamoose!
			-- tell root we have a loose thread!
			self.root:push({self.name, '~&', {}})
			-- tell the thread to die
			if self.thread then self.chan:push({self.name, '&', {}}) end
			-- remove us from the system
			TLSC[self.name] = nil
			if self.islocal then TLLSC[name] = nil end
			self = nil
		end
	end
end

function Strand:start(islocal)
	if not islocal then
		self.thread = love.thread.newThread(default_thread)
		self.thread:start(self.name,self.onload)
	end
end

function Strand:push(tab)
	if self.thread then
		-- we are a thread strand, so pass the message to them
		self.chan:push(tab)
	else
		-- we are a local strand, so just execute the message? maybe?
		local f = self.command[tab[2]]
		if f then
			if type(f) == 'function' then f(self,tab[1],tab[2],tab[3]) end
		end
	end
end

function Strand:exec(name,cmd,var)
	local f = self.command[cmd]
	if f then
		local ret = f(self,name,cmd,var)
		if ret and name ~= self.name then
			self:sendTo(name, { self.name, "~", ret })
		end
	elseif self.command['?'] then
		-- a default handler, so do that!
		local ret = self.command['?'](self,name,cmd,var)
		if ret and name ~= self.name then
			self:sendTo(name, { self.name, "~", ret })
		end
	end
end

-- either a: function, bytecode string from string.dump(), or lua code in func
function Strand:setCmd(cmd,func)
	if type(func) == 'function' then
		self.command[cmd] = func
		if self.thread then
			-- we are a thread strand, so pass the message to them
			self.chan:push({ self.name, '+', { cmd, string.dump(func) }})
		end
	else 
		self.command[cmd] = loadstring(func)
		if self.thread then
			-- we are a thread strand, so pass the message to them
			self.chan:push({ self.name, '+', { cmd, func }})
		end
	end
end

function Strand:unsetCmd(cmd)
	self.command[cmd] = nil
	if self.thread then
		-- we are a thread strand, so pass the message to them
		self.chan:push({ self.name, '-', { cmd }})
	end
end

function Strand:unsetCmds()
	self.command = {}
	if self.thread then
		-- we are a thread strand, so pass the message to them
		self.chan:push({ self.name, '|', {}})
	end
end

function Strand:pump()
	if self.islocal then
		local msg = self.chan:pop()
		while msg do
			-- do it
			local name = msg[1]
			local cmd = msg[2]
			local var = msg[3]
			self:exec(name,cmd,var)
			-- another?
			msg = self.chan:pop()
		end
	end
end

strandRoot = Strand('/',true)

--[[
	Root has some logic built-in:
		- tracking loose threads
		- organizing lists of strands (chains)
		- adding/removing a global variables
	so add that:
]]
strandRoot.loose_threads = {}
strandRoot.loose_count = 0
strandRoot.chains = {}

strandRoot.command['~&'] = function(self,name,cmd,var)
	-- record a loose thread
	self.loose_threads[name] = true
	strandRoot.loose_count = strandRoot.loose_count + 1
end

strandRoot.command['&&'] = function(self,name,cmd,var)
	-- this one has ended, so remove the loose thread indicator
	self.loose_threads[name] = nil
	strandRoot.loose_count = strandRoot.loose_count - 1
end

strandRoot.command['@+'] = function(self,name,cmd,var)
	-- add to a chain
	if self.chains[var[1]] then
		self.chains[var[1]][name] = true
	else
		self.chains[var[1]] = { name = true }
	end 
end

strandRoot.command['G+'] = function(self,name,cmd,var)
	-- add to globals
	for k,v in pairs(var) do
		strandSetGlobal(k,v)
	end
end

strandRoot.command['G-'] = function(self,name,cmd,var)
	-- remove from globals
	for _,v in ipairs(var) do
		strandSetGlobal(v,nil)
	end
end

strandRoot.command['@-'] = function(self,name,cmd,var)
	-- remove from a chain
	if self.chains[var[1]] and self.chains[var[1]][name] then
		self.chains[var[1]][name] = nil
	end 
end

strandRoot.command["?"] = function(self,name,cmd,var)
	-- message all in the chain 'cmd'
	if self.chains[cmd] then
		for k,_ in pairs(self.chains[cmd]) do
			chanTable[k]:push({name, cmd, var})
		end
	end
end

function strandUpdate(dt)
	-- update default counters
	strandVarMap.frame = strandVarMap.frame + 1
	strandVarMap.clock = strandVarMap.clock + dt

	-- inform all the strands of the new globals
	for _, _strand in pairs(TLSC) do
		_strand:push({ '/', '*', strandVarMap })
    end

    -- process local strands
	for _, _strand in pairs(TLLSC) do
		_strand:pump()
    end
end

function strandSetGlobal(k,v)
	strandVarMap[k] = v
end
