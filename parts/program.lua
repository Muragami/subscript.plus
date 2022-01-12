--[[
	General (not specific) logic for the game, running in strands.

	A program is a collection of strands that is configured to work as (async) parts of the game level.
	These are broken into vague types:

		* Algorithm: (.algo.lua) A logic that does mass computation to solve for problems.
		* Controller: (.con.lua) A logic that makes 'choices' based on input.
		* Generator: (.gen.lua) A logic that generates data, procedurally.

	Jason A. Petrasko (C) 2022
]]

local Object = require "classic"

local function starts_with(str, start)
   return str:sub(1, #start) == start
end

local function ends_with(str, ending)
   return ending == "" or str:sub(-#ending) == ending
end

-- global table holding all programs ever loaded
TLPC = {}

Program = {}

function Program.load(the_level)
	-- already loaded? return that
	if TLPC[the_level] then return TLPC[the_level] end
	-- ok, go in and load the program
	local ret = { pfile = {}, func = {}, strand = {}, map = {}, nmap = {}, pstack = {}, pstack_pos = -1 }
	local files = love.filesystem.getDirectoryItems("level/" .. the_level .. "/")
	for k, file in ipairs(files) do
		local full_name = "level/" .. the_level .. "/" .. file
		if ends_with(file,".algo.lua") then
			local chunk, err = love.filesystem.load(full_name)
			if err then error("Program.load() on [" .. the_level .. "] error in [" .. file .. "]: " .. err) end
			ret.pfile[file] = chunk
		elseif ends_with(file,".con.lua") then
			local chunk, err = love.filesystem.load(full_name)
			if err then error("Program.load() on [" .. the_level .. "] error in [" .. file .. "]: " .. err) end
			ret.pfile[file] = chunk
		elseif ends_with(file,".gen.lua") then
			local chunk, err = love.filesystem.load(full_name)
			if err then error("Program.load() on [" .. the_level .. "] error in [" .. file .. "]: " .. err) end
			ret.pfile[file] = chunk
		end
	end
	ret.init = function(self)
		-- start this program
		for k, v in pairs(self.pfile) do
			local f = v()
			self.func[k] = f
			self.map[f.conf.addr] = f
			self.nmap[f.conf.name] = f
			if f.conf.init then
				-- start this strand right now
				self:start(k)
			end
			if f.conf.lead then self.lead_con = k end
		end
	end
	ret.kill = function(self)
		-- kill this program, but strands might stay if they have [static = true] in .conf
	end
	ret.update = function(self,x)
		-- called each update
	end
	ret.start = function(self,name)
		-- start a strand of this program
		local f = self.func[name]
		if f then
			if not f.strand then
				local s
				if f.load then 
					s = Strand(f.conf.name,false,string.dump(f.load))
				else 
					s = Strand(f.conf.name)
				end
				self.strand[name] = s
				f.strand = s
				-- put all it's functions in the pstack!
				for k, v in pairs(f.func) do
					s:setCmd(k,v)
				end
			end
		end
	end

	-- store it
	TLPC[the_level] = ret
	-- at the top level too!
	addTopObject("/PRG:" .. the_level,ret)
	-- return a handle to this program
	return ret
end

