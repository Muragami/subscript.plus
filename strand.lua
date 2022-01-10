--[[
	Messaging for threads in Love2d.
	Jason A. Petrasko (C) 2022
	< MIT License, https://opensource.org/licenses/MIT >
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

-- VarMap, a top level table of global variables to sync to all strands
strandVarMap = { frame = 0, clock = 0 }

Strand = Object:extend()

function Strand:new(name,code_string)
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
		self:setCode(code_string)
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
			self = nil
		end
	end
end

function Strand:setCode(str)
	if type(str) == 'string' then
		if str ~= '' then 
			-- custom code for this strand, so make that thread
			self.thread = love.thread.newThread("local _name = ...\nrequire 'strand.thread'\n\n" .. str)
		end
	elseif not str then
		-- install the default thread, which is a programmable function table
		self.thread = love.thread.newThread("strand.default.lua")
	else
		error("Strand:setCode() called with something other than a string or nil!")
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

strandRoot = Strand('/','')

--[[
	Root has some logic built-in:
		- tracking loose threads
		- organizing lists of strands (chains)
	so add that:
]]
strandRoot.loose_threads = {}
strandRoot.chains = {}

strandRoot.command['~&'] = function(self,name,cmd,var)
	-- record a loose thread
	self.loose_threads[name] = true
end

strandRoot.command['&&'] = function(self,name,cmd,var)
	-- this one has ended, so remove the loose thread indicator
	self.loose_threads[name] = nil
end

strandRoot.command['@+'] = function(self,name,cmd,var)
	-- add to a chain
	if self.chains[var[1]] then
		self.chains[var[1]][name] = true
	else
		self.chains[var[1]] = { name = true }
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

function strandRootActions()
	local msg = strandRoot.chan:pop()
	while msg do
		-- do it
		local name = msg[1]
		local cmd = msg[2]
		local var = msg[3]
		strandRoot:exec(name,cmd,var)
		-- another?
		msg = strandRoot.chan:pop()
	end
end

function strandCheckErrors(onError)
	for _, _strand in pairs(TLSC) do
		if _strand.thread then 
        	local err = _strand.thread:getError()
        	if onError and err then
        		onError(strand.name, err)
        	else 
        		assert(not err, err)
        	end
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

    -- let root do root stuff
    strandRootActions()
end

function strandSetGlobal(k,v)
	strandVarMap[k] = v
end
