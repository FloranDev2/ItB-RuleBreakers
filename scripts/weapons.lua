local path = mod_loader.mods[modApi.currentMod].scriptPath
local customAnim = require(path.."libs/customAnim")

------------------------
--- HELPER FUNCTIONS ---
------------------------

local function isMission()
	local mission = GetCurrentMission()

	return true
		and isGame()
		and mission ~= nil
		and mission ~= Mission_Test
end

local function missionData()
	local mission = GetCurrentMission()

	if mission.truelch_RuleBreakers == nil then
		mission.truelch_RuleBreakers = {}
	end

	--missionData().sawStatus[pawnId] =
	---> 0: sawblade is on the mech
	---> 1: sawblade is dead
	---> <sawblade's id>: sawblade is alive!
	if truelch_RuleBreakers == nil then
		mission.truelch_RuleBreakers.sawStatus = {}
	end

	return mission.truelch_RuleBreakers
end

--[[
local function isVarNil(msg, var)
	if var == nil then
		LOG("----------- "..msg.." is nil :(")
	else
		LOG("----------- "..msg.." exists :)")
	end
end
]]

--Game:GetPower()


-------------------------
--- Sawblade launcher ---
-------------------------

local function addSawBlade(pawn)
	LOG("addSawBlade")
	if pawn == nil then return end
	missionData().sawStatus[pawn:GetId()] = 0
	--TODO: add custom anim
end

local function isSawbladePawn(pawn)
	if pawn ~= nil and (pawn:GetType() == "truelch_Sawblade" or pawn:GetType() == "truelch_Sawblade_A") then
		return true
	end
	return false
end

truelch_SawbladeLauncher = Skill:new{
	--Infos
	Name = "Sawblade Launcher",
	Description = "Launch a sawblade, dealing 2 damage in its path.",
	Class = "Brute",
	Icon = "weapons/truelch_burrower_attack.png",

	ArtilleryHeight = 0, --artillery arc

	--Shop
	Rarity = 1,
	PowerCost = 0,
	
	Upgrades = 2,
	UpgradeCost = { 1, 2 },

	--Gameplay
	Damage = 2,
	EscalatingDamage = 0,
	Range = 4,
	SawbladePawn = "truelch_Sawblade",

	ReturnDamage = 3,
	ReturnSelfDamage = 1,

	--Art
	LaunchSound = "",
	SoundBase = "/enemy/burrower_1/",

	--Tip image
	TipImage = {
		--[[
		Unit   = Point(2, 2),
		Enemy  = Point(2, 1),
		Enemy2 = Point(1, 1),
		Target = Point(2, 1),
		CustomPawn = "truelch_BurrowerMech",

        Second_Origin = Point(2, 2),
        Second_Target = Point(3, 2),
        Building = Point(3, 2),
        Enemy3 = Point(3, 3),
		]]
	}
}

modApi:addWeaponDrop("truelch_SawbladeLauncher")

Weapon_Texts.truelch_SawbladeLauncher_Upgrade1 = "Reinforced Sawblade"
Weapon_Texts.truelch_SawbladeLauncher_Upgrade2 = "Escalating Damage"


truelch_SawbladeLauncher_A = truelch_SawbladeLauncher:new{
	UpgradeDescription = "The sawblade gets +2 hp and +1 Thorns damage.",
	SawbladePawn = "truelch_Sawblade_A",
}

truelch_SawbladeLauncher_B = truelch_SawbladeLauncher:new{
	UpgradeDescription = "+1 Damage for each unit killed.",
	EscalatingDamage = 1,
}

truelch_SawbladeLauncher_AB = truelch_SawbladeLauncher:new{
	SawbladePawn = "truelch_Sawblade_A",
	EscalatingDamage = 1,
}

function truelch_SawbladeLauncher:GetSawbladeStatus()
	LOG("truelch_SawbladeLauncher:GetSawbladeStatus()")

	if missionData().sawStatus[Pawn:GetId()] == nil then
		LOGF("-------------- OH NO: mission().sawStatus[%s] == nil", tostring(Pawn:GetId()))
		return -1 --error
	end

	if missionData().sawStatus[Pawn:GetId()] == 0 then
		--Sawblade exists on the Mech
		return self:LaunchSawblade()
	elseif missionData().sawStatus[Pawn:GetId()] == 1 then
		--Sawblade is dead
		return self:RebuildSawblade(p1, p2)
	else
		--Note: the value here is the id of the saw blade
		--Sawblade has been launched and is still alive
		return self:ReturnSawblade(p1, p2)
	end

end

-- mission().sawStatus
-- 0: Sawblade on the Mech
function truelch_SawbladeLauncher:GetTargetArea(point)
	local ret = PointList()

	for dir = DIR_START, DIR_END do
		for i = 1, self.Range do
			local curr = point + DIR_VECTORS[dir]*i
			ret:push_back(curr)
		end
	end
	
	return ret
end

function truelch_SawbladeLauncher:LaunchSawblade(p1, p2)
	local ret = SkillEffect()

	--TODO: remove custom anim (in AddScript)

	local dir = GetDirection(p2 - p1)
	local dist = p1:Manhattan(p2)
	local currEscDmg = 0

	for i = 1, dist do
		local curr = p1 + DIR_VECTORS[dir] * i
		local spaceDamage = SpaceDamage(curr, self.Damage + currEscDmg)
		ret:AddDamage(spaceDamage)

		ret:AddDelay(0.1)

		if Board:IsDeadly(spaceDamage, Pawn) then
			currEscDmg = currEscDmg + self.EscalatingDamage
		end
	end

	return ret
end

function truelch_SawbladeLauncher:ReturnSawblade(p1, p2)
	local ret = SkillEffect()



	return ret
end

function truelch_SawbladeLauncher:RebuildSawblade(p1, p2)
	local ret = SkillEffect()

	ret:AddScript("addSawBlade(Pawn)")

	return ret
end


function truelch_SawbladeLauncher:GetSkillEffect(p1, p2)
	local ret = SkillEffect() --tmp?

	LOG("truelch_SawbladeLauncher:GetSkillEffect - A")

	local status = self:GetSawbladeStatus()

	LOG(" -----------  status: "..tostring(status))

	if status == nil or status == -1 then --error!
		LOG(" ----------- return error")
		return ret --maybe we should attempt to rebuild the sawblade in that case?
	end

	if status == 0 then
		--sawblade is on the mech
		LOG(" ----------- sawblade is on the mech")
		return self:LaunchSawblade(p1, p2)
	elseif status == 1 then
		--sawblade is dead
		LOG(" ----------- sawblade is dead")
		return self:RebuildSawblade(p1, p2)
	else
		--sawblade is on the board and still alive!
		--in that case, status is actually the sawblade's id!
		LOG(" ----------- sawblade is alive!")
		return self:ReturnSawblade(p1, p2)
	end

	LOG(" ----------- wait... what??")

	--Should not be needed
	return ret --tmp

end


--------------
--- Events ---
--------------

local function EVENT_onMissionStarted(mission)
	LOG("EVENT_onMissionStarted")
	for i = 0, 2 do
		local mech = Board:GetPawn(i)

		LOGF("[%s] mech: %s", tostring(i), mech:GetMechName())
		
		--Returns true if the pawn has powered a weapon of type weapon or a less powered variant of it. false otherwise.
		--just using mech:IsWeaponPowered("truelch_SawbladeLauncher_AB") did NOT work with base version, unlike what documentation described.
		if mech:IsWeaponPowered("truelch_SawbladeLauncher") or
				mech:IsWeaponPowered("truelch_SawbladeLauncher_A") or
				mech:IsWeaponPowered("truelch_SawbladeLauncher_B") or
				mech:IsWeaponPowered("truelch_SawbladeLauncher_AB") then --this should be the only one required but it didn't work for the base weapon
			LOG(" -----> "..mech:GetMechName().." is equipped with a Sawblade launcher")
			addSawBlade(mech)
		else
			LOG(" -----> not equipped with sawblade launcher")
		end
	end
end

local function EVENT_onPawnKilled(mission, pawn)
	if pawn == nil then return end

	if isSawbladePawn(pawn) then
		for i = 0, 2 do
			if missionData().sawStatus[i] ~= nil and missionData().sawStatus[i] == pawn:GetId() then
				missionData().sawStatus[i] = 1 --dead
			end
		end
	end
end

modApi.events.onMissionStart:subscribe(EVENT_onMissionStarted)
modapiext.events.onPawnKilled:subscribe(EVENT_onPawnKilled)
