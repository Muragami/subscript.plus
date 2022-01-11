--[[
	Rendering class for the game.
	Jason A. Petrasko (C) 2022
]]

Object = require "classic"

require "parts/rload"

Artist = Object:extend()

function Artist:load()
	--ftest = Font("compaq_port3")
	ftest = Font("dinobyte")
	ttest = Text(ftest)
	x = 0
	p = 0
	ttest:set("ripple",false)
	ttest:set("vflip",0.05)
end

function Artist:update(tab)
	ttest:update(tab[1])
	x = x + 1
	p = p + (tab[1] * 20)
	if p > 100 then p = p - 100 end
end

function Artist:draw()
	ttest:drawRight(10,10,"Testing dirty text renderer. FRAME= " .. tostring(x))

	ttest:drawDown(10,28,"*#*@*#][*#")

	ttest:drawBox(60,60,29,5)

	ttest:drawPercentageBar(84,92,p,25)
end

return Artist