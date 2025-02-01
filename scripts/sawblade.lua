local resourcePath = mod_loader.mods[modApi.currentMod].resourcePath
local scriptPath = mod_loader.mods[modApi.currentMod].scriptPath
local mechPath = resourcePath .."img/mechs/"
local mod = modApi:getCurrentMod()
--local mechDiversYellow = modApi:getPaletteImageOffset("truelch_MechDiversYellow")

--to do for both sawblade and upgraded saw blade:
--[[
local trait = require(scriptPath.."/libs/trait") --unnecessary?
trait:add{
    pawnType = "truelch_Sawblade",
    icon = "img/combat/icons/icon_protecc.png",
    icon_offset = Point(0, 0),
    desc_title = "Thorns",
    desc_text = "Any damage caused during player's turn to a Building will be redirected to any adjacent Emancipator Mech."
}
]]

truelch_Sawblade = Pawn:new{
	Name = "Sawblade",
	Health = 1,
	MoveSpeed = 0,
	Image = "Bombling",
	SkillList = { },
	SoundLocation = "/mech/flying/jet_mech/",
	ImageOffset = 9,
	DefaultTeam = TEAM_PLAYER,
	ImpactMaterial = IMPACT_METAL,
	Corpse = false,
	--Pushable = false,
}
AddPawn("truelch_Sawblade")

truelch_Sawblade_A = truelch_Sawblade:new{
	Name = "Reinforced Sawblade",
	Health = 3,
}
AddPawn("truelch_Sawblade_A")

--------------
--- Events ---
--------------

--[[
local function isVarNil(msg, var)
	if var == nil then
		LOG("----------- "..msg.." is nil :(")
	else
		LOG("----------- "..msg.." exists :)")
	end
end
]]

local function isSawbladePos(point)
	local pawn = Board:GetPawn(point)
	if pawn ~= nil and (pawn:GetType() == "truelch_Sawblade" or pawn:GetType() == "truelch_Sawblade_A") then
		return true
	end
	return false
end

--p1 is the pos of the shooter. With this, we can check if we are in melee range
local function computeThornDamage(p1, se)
	if se == nil or se.effect == nil then return end

	for i = 1, se.effect:size() do
		local spaceDamage = se.effect:index(i)
		local loc = spaceDamage.loc
		local dist = p1:Manhattan(loc)
		if isSawbladePos(loc) and dist == 1 then
			LOG("Here!")
			local thornDamage = SpaceDamage(p1, 1)
			--TODO: animation
			se:AddDamage(thornDamage)
		end
	end

end


--Wait, the following doesn't give me a SkillEffect
--[[
local function EVENT_onSkillEnd(mission, pawn, weaponId, p1, p2, skillEffect)
	computeThornDamage(p1, skillEffect)
end

local function EVENT_onFinalEffectEnd(mission, pawn, weaponId, p1, p2, p3, skillEffect)
	computeThornDamage(p1, skillEffect)
end

modapiext.events.onSkillEnd:subscribe(EVENT_onSkillEnd)
modapiext.events.onFinalEffectEnd:subscribe(EVENT_onFinalEffectEnd)
]]

--No, this happens during get skill effect. I want to way that the skill is effectively passed to the game!
--Or maybe not
local function EVENT_onSkillBuild(mission, pawn, weaponId, p1, p2, skillEffect)
	computeThornDamage(p1, skillEffect)
end

local function EVENT_onFinalEffectBuild(mission, pawn, weaponId, p1, p2, p3, skillEffect)
	computeThornDamage(p1, skillEffect)
end

modapiext.events.onSkillBuild:subscribe(EVENT_onSkillBuild)
modapiext.events.onFinalEffectBuild:subscribe(EVENT_onFinalEffectBuild)
