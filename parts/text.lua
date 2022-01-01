--[[
	Text visuals for the game.
	Jason A. Petrasko (C) 2022
]]

local iffy = require "iffy"

-- discover all loadable fonts and put their names into a table
local function starts_with(str, start)
   return str:sub(1, #start) == start
end

local function ends_with(str, ending)
   return ending == "" or str:sub(-#ending) == ending
end

local function buildFontTable()
	local files = love.filesystem.getDirectoryItems("img/")
	local ret = {}
	for k, file in ipairs(files) do
		if ends_with(file,".fnt.lua") then
			ret[file] = true
		end
	end
	return ret
end

fntFiles = buildFontTable()

local Object = require "classic"

Font = Object:extend()

function Font:new(str)
	-- see if the font exists and if it does, load it!
	if fntFiles[str .. ".fnt.lua"] then
		self.data = love.filesystem.load("img/" .. str .. ".fnt.lua")()
		self.quads = iffy.newTileset(str,"img/" .. str .. ".fnt.png",self.data.width,self.data.height)
		self.tex = iffy.getImage(str)
		self.tex:setFilter("nearest","nearest")
	else
		error("The font '" .. str .. "' not found!")
	end
	self.type = "font"
end

Text = Object:extend()

function Text:new(fnt)
	if type(fnt) ~= "table" or fnt.type ~= "font" then
		error("Bad parameter: " .. tostring(fnt) .. " sent to Text:new()")
	end
	self.fnt = fnt
	self.h = fnt.data.height
	self.w = fnt.data.width
	self.variant = 0
	self.vflip = 0.1
	self.clock = 0.0
	self.flicker = 0
	self.worst = (self.fnt.data.variants - 1) * self.fnt.data.chars
	self.ripple = { 0, 0, 0, 0, 0, 0, 0, 0 }
	self.ripplev = { 1, 1, 1, 1, 1, 1, 1, 1 }
	self.ripplemap = { 0, 0.77, 0, -0.77 }
	self.offset = { 0, 0, 0, 0, 0, 0, 0, 0 }
	self.rng = love.math.newRandomGenerator()
end

function Text:update(dt)
	self.clock = self.clock + dt
	if self.vflip and self.clock > self.vflip then
		self.clock = self.clock - self.vflip
		local i = self.rng:random(8)
		self.ripplev[i] = self.ripplev[i] + 1
		if self.ripplev[i] == #self.ripplemap then self.ripplev[i] = 1 end
		self.ripple[i] = self.ripplemap[self.ripplev[i]]
		i = self.rng:random(8)
		self.offset[i] = (self.rng:random(self.fnt.data.variants) - 1) * self.fnt.data.chars
	end
end

function Text:set(opt,var,var2)
	if opt == "ripple" then
		if not var then
			self.ripple = { 0, 0, 0, 0, 0, 0, 0, 0 }
			self.ripplemap = { 0, 0, 0, 0 }
		elseif var == true then
			self.ripple = { 0, 0, 0, 0, 0, 0, 0, 0 }
			self.ripplemap = { 0, 0.77, 0, -0.77 }
		end
	elseif opt == "vflip" then
		self.vflip = var
	end
end

function Text:drawRight(x, y, str, s)
	if not s then s = 1 end
	for i = 1, #str do
    	local c = str:byte(i)
    	local o = i % 8
    	if o == 0 then o = 8 end
    	if self.rng:random(100) <= self.flicker then
    		love.graphics.draw(self.fnt.tex, self.fnt.quads[1 + c + self.worst], x, y + (self.ripple[o] * 1.5), 0, s, s)
    		love.graphics.draw(self.fnt.tex, self.fnt.quads[1 + c + self.worst], x + (self.rng:random(3) - 2), y + (self.ripple[o] * 1.5), 0, s, s)
    	else 
    		love.graphics.draw(self.fnt.tex, self.fnt.quads[1 + c + self.offset[o]], x, y + self.ripple[o], 0, s, s)
    	end
    	x = x + self.w * s
	end
end

function Text:drawDown(x, y, str, s)
	if not s then s = 1 end
	for i = 1, #str do
    	local c = str:byte(i)
    	local o = i % 8
    	if o == 0 then o = 8 end
    	if self.rng:random(100) <= self.flicker then
    		love.graphics.draw(self.fnt.tex, self.fnt.quads[1 + c + self.worst], x, y + (self.ripple[o] * 1.5), 0, s, s)
    		love.graphics.draw(self.fnt.tex, self.fnt.quads[1 + c + self.worst], x + (self.rng:random(3) - 2), y + (self.ripple[o] * 1.5), 0, s, s)
    	else 
    		love.graphics.draw(self.fnt.tex, self.fnt.quads[1 + c + self.offset[o]], x, y + self.ripple[o], 0, s, s)
    	end
    	y = y + self.h * s
	end
end

function Text:drawBox(x, y, w, h, sf)
	if w < 4 or h < 4 then error("Text:drawBox() called with w or h less than 4!") end
	local s = {}
	table.insert(s,string.char(201))
	for i = 1, w-2, 1 do
		table.insert(s,string.char(205))
	end
	table.insert(s,string.char(187))
	self:drawRight(x,y,table.concat(s),sf)
	s[1] = string.char(200)
	s[w] = string.char(188)
	self:drawRight(x,y+((h-1)*self.h),table.concat(s),sf)
	local d = string.rep(string.char(186),h-2)
	self:drawDown(x,y + self.h,d,sf)
	self:drawDown(x + (self.w * (w - 1)),y + self.h,d,sf)
end

function Text:drawLineBox(x, y, w, h, sf)
	if w < 4 or h < 4 then error("Text:drawBox() called with w or h less than 4!") end
	local s = {}
	table.insert(s,string.char(218))
	for i = 1, w-2, 1 do
		table.insert(s,string.char(196))
	end
	table.insert(s,string.char(191))
	self:drawRight(x,y,table.concat(s),sf)
	s[1] = string.char(192)
	s[w] = string.char(217)
	self:drawRight(x,y+((h-1)*self.h),table.concat(s),sf)
	local d = string.rep(string.char(179),h-2)
	self:drawDown(x,y + self.h,d,sf)
	self:drawDown(x + (self.w * (w - 1)),y + self.h,d,sf)
end

function Text:drawPercentageBar(x, y, percent, len, sf)
	if len < 4 then error("Text:drawPercentageBar() called with len under 4!") end
	if percent < 0 then percent = 0 end
	if percent > 100 then percent = 100 end
	local s = string.rep(string.char(254),len)
	self:drawRight(x,y,s,sf)
	local chars = percent * len * 0.01
	local fchars, pchar = math.modf(chars)
	pchar = math.floor(pchar * 4)
	s = string.rep(string.char(219),fchars)
	if pchar > 0 then s = s .. string.char(175 + pchar) end
	self:drawRight(x,y,s,sf)
end

