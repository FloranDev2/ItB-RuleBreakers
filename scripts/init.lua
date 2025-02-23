local mod = {
	id = "truelch_RuleBreakers",
	name = "Rule Breakers",
	icon = "img/mod_icon.png",
	version = "0.0.6",
	modApiVersion = "2.9.2",
	--gameVersion = "1.2.88",
    	dependencies = {
		memedit = "1.0.4",
    	modApiExt = "1.21",
    }
}

function mod:init()
	--Libs (weapon armed is just required by artilleryArc)
	require(self.scriptPath.."/libs/artilleryArc")
	require(self.scriptPath.."/libs/customAnim")
	require(self.scriptPath.."/libs/trait")
	require(self.scriptPath.."/libs/tutorialTips")

	require(self.scriptPath.."functions")
	require(self.scriptPath.."assets")
	require(self.scriptPath.."palette")
	--require(self.scriptPath.."achievements")
	require(self.scriptPath.."sawblade")

	require(self.scriptPath.."pawns")
	require(self.scriptPath.."/weapons/debug_weapon")
	require(self.scriptPath.."/weapons/sawblade_launcher")
	require(self.scriptPath.."/weapons/grid_shield")
	require(self.scriptPath.."/weapons/grid_discharge")
	require(self.scriptPath.."/weapons/rift_inducer")

	--Options
	modApi:addGenerationOption("option_smoothed_line",
		"Smooth line",
		"Damage dealt by the sawblade depends on the distance.",
		{enabled = false}
	)
	
	modApi:addGenerationOption("option_diagonal_launch",
		"Diagonal launch",
		"Launching sawblade can also be diagonal.",
		{enabled = true}
	)

	modApi:addGenerationOption("option_rift_area",
		"Rift Inducer's second area",
		[[Second area can be lines from the first point, squares around it or "diamond-shaped" (manhattan distance).]],
		{	--1: lines, 2: squares, 3: manhattan
			values = {1, 2, 3},
			value = 3,
			strings = { "Lines", "Squares", "Manhattan" }
		}
	)

	modApi:addGenerationOption("option_sawblade_rebuild",
		"Rebuild Sawblade effect",
		"What should happen when the sawblade.",
		{	--1: nothing, 2: push, 3: vortex
			values = {1, 2, 3},
			value = 1,
			strings = { "Nothing", "Push", "Vortex" }
		}
	)
end

function mod:load(options, version)
	modApi:addSquad(
		{
			id = "truelch_RuleBreakers",
			"Rule Breakers",
			"truelch_SawbladeMech",
			"truelch_GridMech",
			"truelch_DislocationMech",
		},
		"Rule Breakers",
		"Original idea from nopro.",
		self.resourcePath.."img/squad_icon.png"
	)
end

return mod