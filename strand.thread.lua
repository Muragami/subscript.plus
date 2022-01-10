--[[
	Messaging for threads in Love2d.
	Jason A. Petrasko (C) 2022
	< MIT License, https://opensource.org/licenses/MIT >
]]

local chanTable = setmetatable( {}, {
	__index = function (table, key)
		local v = love.thread.getChannel(key)
  		rawset(table, key, v)
  		return v
	end } )

local thread = {
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

local function addCmdFunc(thread, name, cmd, var)
	thread:setCmdFunc(var[1], var[2])
end

local function remCmdFunc(thread, name, cmd, var)
	thread:unsetCmdFunc(var[1])
end

local function remCmds(thread, name, cmd, var)
	thread:unsetCmds()
end

local function endThread(thread, name, cmd, var)
	thread.valid = false
	-- if we are going out with a bang, do that!
	if thread.command['!'] then
		thread.command['!'](thread,name,'!',{})
	end
end

local function setVars(thread, name, cmd, var)
	for k, v in pairs(var) do
		thread.var[k] = v
	end
end

function thread:init()
	self.command['+'] = addCmdFunc
	self.command['-'] = remCmdFunc
	self.command['|'] = remCmds
	self.command['&'] = endThread
	self.command['*'] = setVars
end
