local mod = {
	id = "truelch_RuleBreakers",
	name = "Rule Breakers",
	icon = "img/mod_icon.png",
	version = "0.0.7",
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

	--test
	require(self.scriptPath.."/libs/buildingDeploy")

	require(self.scriptPath.."functions")
	require(self.scriptPath.."assets")
	require(self.scriptPath.."palette")
	--require(self.scriptPath.."achievements")
	require(self.scriptPath.."sawblade")

	--test
	--require(self.scriptPath.."test_qte")

	require(self.scriptPath.."pawns")
	require(self.scriptPath.."/weapons/debug_weapon")
	require(self.scriptPath.."/weapons/sawblade_launcher")
	require(self.scriptPath.."/weapons/grid_shield")
	require(self.scriptPath.."/weapons/grid_discharge")
	require(self.scriptPath.."/weapons/rift_inducer")

	--Options
	modApi:addGenerationOption("option_rift_area",
		"Rift Inducer's second area",
		[[Second area can be lines from the first point, squares around it or "diamond-shaped" (manhattan distance).]],
		{	--1: lines, 2: squares, 3: manhattan
			values = {1, 2, 3},
			value = 3,
			strings = { "Lines", "Squares", "Manhattan" }
		}
	)

	modApi:addGenerationOption("option_grid_shield",
		"Grid Shield",
		"Either shield self and building below or just shield a nearby building.\nNote: shielding just the building didn't work well visually.",
		{	--1: lines, 2: squares, 3: manhattan
			values = {1, 2, 3},
			value = 3,
			strings = { "Grid self + building below", "Shield nearby building" }
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