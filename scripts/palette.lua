--[[
modApi:addPalette({
		ID = "truelch_RuleBreakersMagenta",
		Name = "R",
		Image = "img/units/player/MechTritube.png",
		PlateHighlight = { 197, 239, 217 },	--lights
		PlateLight     = { 166, 143, 183 }, --main highlight
		PlateMid       = { 133, 106, 145 }, --main light
		PlateDark      = {  78,  43,  89 },	--main mid
		PlateOutline   = {  42,  14,  51 },	--main dark
		PlateShadow    = { 137, 121,  81 },	--metal dark
		BodyColor      = { 193, 165, 100 },	--metal mid
		BodyHighlight  = { 255, 243, 178 },	--metal light
})
]]
modApi:addPalette({
		ID = "truelch_RuleBreakersMagenta", --not magenta at all, i'm experimenting atm
		Name = "R",
		Image = "img/units/player/MechTritube.png",
		PlateHighlight = { 197, 239, 217 },	--lights
		PlateLight     = { 146, 146, 183 }, --main highlight
		PlateMid       = {  70,  82,  96 }, --main light
		PlateDark      = {  24,  52,  63 },	--main mid
		PlateOutline   = {   5,  28,  38 },	--main dark
		PlateShadow    = {  68,  21,  10 },	--metal dark
		BodyColor      = { 193,  77,  38 },	--metal mid
		BodyHighlight  = { 255, 213,  45 },	--metal light
})
modApi:getPaletteImageOffset("truelch_RuleBreakersMagenta")