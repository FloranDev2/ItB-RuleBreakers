---------------
--- IMPORTS ---
---------------

local mod = modApi:getCurrentMod()

local resourcePath = mod.resourcePath
local scriptPath = mod.scriptPath

local mechPath = resourcePath .."img/mechs/"

local functions = require(scriptPath.."functions")


-------------
--- TRAIT ---
-------------

--to do for both sawblade and upgraded saw blade:
local trait = require(scriptPath.."/libs/trait") --unnecessary?
trait:add{
    pawnType = "truelch_Sawblade",
    icon = "img/combat/icons/icon_sawblade_trait.png",
    icon_offset = Point(0, 0),
    desc_title = "Swablade",
    desc_text = "Units attacking the sawblade in melee range will take 1 damage."
}


--truelch_Sawblade_A deals more return damage
trait:add{
    pawnType = "truelch_Sawblade_A",
    icon = "img/combat/icons/icon_sawblade_trait.png",
    icon_offset = Point(0, 0),
    desc_title = "Reinforced Sawblade",
    desc_text = "Units attacking the sawblade in melee range will take 2 damage."
}


------------
--- PAWN ---
------------

truelch_Sawblade = Pawn:new{
	Name = "Sawblade",
	Health = 1,
	MoveSpeed = 0,
	Image = "truelch_sawblade",
	SkillList = { "truelch_SawbladeSelfDestruct"--[[, "truelch_SawbladeDisarm"]] },
	SoundLocation = "", --"/mech/flying/jet_mech/"
	ImageOffset = 9,
	DefaultTeam = TEAM_PLAYER,
	ImpactMaterial = IMPACT_METAL,
	Corpse = false,
	Flying = true,
}
--AddPawn("truelch_Sawblade")

truelch_Sawblade_A = truelch_Sawblade:new{
	Name = "Reinforced Sawblade",
	Health = 3,
	Image = "truelch_sawblade_A",
	--SkillList = { "truelch_SawbladeSelfDestruct" }, --why is it necessary? WTF even with this it doesn't work
}
--AddPawn("truelch_Sawblade_A")


-----------------------------
--- SKILL (SELF-DESTRUCT) ---
-----------------------------

truelch_SawbladeSelfDestruct = Skill:new{
	--Infos
	Name = "Sawblade self-destruct",
	Description = "Sawblade shatters itself to project deadly shards of metal, damaging and pushing adjacent tiles.",
	--Class = "",
	Icon = "weapons/support_destruct.png",

	--Gameplay
	Damage = 1,
	Push = true,

	--Tip image
	TipImage = StandardTips.Surrounded
}

function truelch_SawbladeSelfDestruct:GetTargetArea(point)
	local ret = PointList()
	ret:push_back(point)	
	return ret
end

function truelch_SawbladeSelfDestruct:GetSkillEffect(p1, p2)
	local ret = SkillEffect()

	--Self-damage
	local selfDmg = SpaceDamage(p2, DAMAGE_DEATH)
	selfDmg.sAnimation = "explo_fire1" --tmp?
	selfDmg.sSound = "/impact/generic/explosion" --tmp?
	ret:AddDamage(selfDmg)
	ret:AddBounce(p1, 3)

	--Adjacent damage
	for dir = DIR_START, DIR_END do
		local curr = p2 + DIR_VECTORS[dir]
		local adjDmg = SpaceDamage(curr, self.Damage)
		if self.Push then
			adjDmg.iPush = dir
		end
		ret:AddDamage(adjDmg)
		ret:AddBounce(curr, 2)
	end

	return ret
end

--[[
truelch_SawbladeDisarm = Skill:new{
	--Infos
	Name = "Disarm",
	Description = "The sawblade self-destruct harmlessly.",
	--Class = "",
	Icon = "weapons/support_destruct.png",

	--Tip image
	TipImage = StandardTips.Surrounded
}

function truelch_SawbladeDisarm:GetTargetArea(point)
	local ret = PointList()
	ret:push_back(point)	
	return ret
end

function truelch_SawbladeDisarm:GetSkillEffect(p1, p2)
	local ret = SkillEffect()

	--Self-damage
	local selfDmg = SpaceDamage(p2, DAMAGE_DEATH)
	selfDmg.sAnimation = "explo_fire1" --tmp?
	selfDmg.sSound = "/impact/generic/explosion" --tmp?
	ret:AddDamage(selfDmg)
	ret:AddBounce(p1, 3)

	return ret
end
]]


---------------
--- EFFECTS ---
---------------

--p1 is the pos of the shooter. With this, we can check if we are in melee range
local function computeThornDamage(p1, se)
	if se == nil or se.effect == nil then return end

    if not se.q_effect:empty() then
        return
    end

	for i = 1, se.effect:size() do
		local spaceDamage = se.effect:index(i)
		local loc = spaceDamage.loc
		local dist = p1:Manhattan(loc)
		if dist == 1 then
			if functions:isSawbladePos(loc) then
				local thornDamage = SpaceDamage(p1, 1)
				--TODO: animation
				se:AddDamage(thornDamage)
			elseif functions:isReinforcedSawbladePos(loc) then
				local thornDamage = SpaceDamage(p1, 2)
				--TODO: animation
				se:AddDamage(thornDamage)
			end
		end
	end

end


--------------
--- EVENTS ---
--------------

local function EVENT_onSkillBuild(mission, pawn, weaponId, p1, p2, skillEffect)
	computeThornDamage(p1, skillEffect)
end

local function EVENT_onFinalEffectBuild(mission, pawn, weaponId, p1, p2, p3, skillEffect)
	computeThornDamage(p1, skillEffect)
end

modapiext.events.onSkillBuild:subscribe(EVENT_onSkillBuild)
modapiext.events.onFinalEffectBuild:subscribe(EVENT_onFinalEffectBuild)