modApi:addPalette({ --Or maybe I should to blue and yellow?
		ID = "truelch_RuleBreakersMagenta",
		Name = "R",
		--Image = "img/units/player/patriotMech_ns.png", --Patriot / Eagle
		PlateHighlight = { 255, 255, 240 },	--lights
		PlateLight     = {  91,  92,  93 }, --main highlight
		PlateMid       = {  51,  52,  53 }, --main light
		PlateDark      = {  30,  30,  28 },	--main mid
		PlateOutline   = {  15,  15,  15 },	--main dark
		PlateShadow    = { 125,  75,  50 },	--metal dark
		BodyColor      = { 175, 100,  75 },	--metal mid
		BodyHighlight  = { 255, 208,  75 },	--metal light
})
modApi:getPaletteImageOffset("truelch_RuleBreakersMagenta")