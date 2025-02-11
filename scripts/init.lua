local mod = {
	id = "truelch_RuleBreakers",
	name = "Rule Breakers",
	icon = "img/mod_icon.png",
	version = "0.0.2",
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

	require(self.scriptPath.."assets")
	require(self.scriptPath.."palette")
	--require(self.scriptPath.."achievements")
	require(self.scriptPath.."sawblade")

	require(self.scriptPath.."pawns")
	--require(self.scriptPath.."/mechs/dislocation_mech")
	--require(self.scriptPath.."/mechs/grid_mech") --move on buildings doesn't work anymore when I split files
	--require(self.scriptPath.."/mechs/sawblade_mech")

	--require(self.scriptPath.."weapons")
	require(self.scriptPath.."/weapons/debug_weapon")
	require(self.scriptPath.."/weapons/sawblade_launcher")
	require(self.scriptPath.."/weapons/grid_shield")
	require(self.scriptPath.."/weapons/grid_discharge")
	require(self.scriptPath.."/weapons/rift_inducer")

	--Options
	modApi:addGenerationOption("option_smoothed_line",
		"Smooth line",
		"Damage dealt by the sawblade depends on the distance.",
		{enabled = true}
	)

	modApi:addGenerationOption("option_diagonal_launch",
		"Diagonal launch",
		"Launching sawblade can also be diagonal.",
		{enabled = false}
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