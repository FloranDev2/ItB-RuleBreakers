local path = mod_loader.mods[modApi.currentMod].scriptPath
local customAnim = require(path.."libs/customAnim")

------------------------
--- HELPER FUNCTIONS ---
------------------------

--[[
local testTable = {}
testTable[0] = "zog"
LOG("testTable[0]: "..testTable[0])
]]

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
	if mission.truelch_RuleBreakers.sawStatus == nil then
		mission.truelch_RuleBreakers.sawStatus = {}
	end

	--[[
	if mission.truelch_RuleBreakers.lastLauncher == nil then
		mission.truelch_RuleBreakers.lastLauncher
	end
	]]

	return mission.truelch_RuleBreakers
end

local function isVarNil(msg, var)
	if var == nil then
		LOG("----------- "..msg.." is nil :(")
	else
		LOG("----------- "..msg.." exists :)")
	end
end

--Game:GetPower()


-------------------------
--- Sawblade launcher ---
-------------------------

local function debugSawStatus()
	LOG("debugSawStatus()")
	LOG("tostring(missionData().sawStatus)): "..tostring(missionData().sawStatus))
	--LOG("tostring(extract_table(missionData().sawStatus)): "..tostring(extract_table(missionData().sawStatus)))

	--[[
	--for i, elem in pairs(missionData().sawStatus) do
	for i, elem in ipairs(missionData().sawStatus) do
		--LOGF("i: %s elem: %s", tostring(i),tostring(elem))
		--LOG("extract elem: "..tostring(extract_table(elem)))
	end
	]]

	--Simpler attempt:
	for i = 0, 2 do
		if missionData().sawStatus[i] ~= nil then
			LOGF("missionData().sawStatus[%s] = %s", tostring(i), tostring(missionData().sawStatus[i]))
		else
			LOGF("missionData().sawStatus[%s] is nil!", tostring(i))
		end
	end
end

local function addSawBlade(pawn)
	LOG("addSawBlade")
	if pawn == nil then
		LOG("pawn == nil -> return")
		return
	end

	missionData().sawStatus[pawn:GetId()] = 0

	--TODO: add custom anim

	--LOG("missionData().sawStatus[pawn:GetId()]: "..tostring(missionData().sawStatus[pawn:GetId()]))

	debugSawStatus()
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
	Icon = "weapons/prime_punchmech.png",

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

	OnKill = "Test",

	--Art
	ProjectileArt = "effects/shot_pierce",
	ShotUpArt = "advanced/effects/shotup_deploybomb.png",
	ArtilleryHeight = 0, --artillery arc

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
	if missionData().sawStatus[Pawn:GetId()] == nil then
		LOGF("-------------- OH NO: mission().sawStatus[%s] == nil", tostring(Pawn:GetId()))
		return -1 --error
	end
	return missionData().sawStatus[Pawn:GetId()]
end

-- mission().sawStatus
-- 0: Sawblade on the Mech
function truelch_SawbladeLauncher:GetTargetArea(point)
	local ret = PointList()

	local status = self:GetSawbladeStatus()

	if status == 0 or status == 1 then
		for dir = DIR_START, DIR_END do
			for i = 1, self.Range do
				local curr = point + DIR_VECTORS[dir]*i
				ret:push_back(curr)
			end
		end
	elseif status == 1 then
		--Sawblade is dead: need to recreate it
		ret:push_back(point)
	elseif status == -1 or status == nil then
		--Error
		LOG("status is nil or equals to -1")
	else
		--Sawblade is alive
		local sawblade = Board:GetPawn(status)
		if sawblade ~= nil then
			ret:push_back(sawblade:GetSpace())
		else
			LOG("WTF! Sawblade is nil while it should exist and be alive")
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

	local projArt = SpaceDamage(p2, 0)
	ret:AddProjectile(projArt, self.ProjectileArt)

	for i = 1, dist do
		local curr = p1 + DIR_VECTORS[dir] * i
		local spaceDamage = SpaceDamage(curr, self.Damage + currEscDmg)
		spaceDamage.sAnimation = "ExploRaining1"
		ret:AddDamage(spaceDamage)

		ret:AddDelay(0.5)

		if Board:IsDeadly(spaceDamage, Pawn) then
			currEscDmg = currEscDmg + self.EscalatingDamage
		end

		if curr == p2 then
			if Board:IsDeadly(spaceDamage, Pawn) then
				--spaceDamage.bKO_Effect = true --??
				spaceDamage.sPawn = self.SawbladePawn
				ret:AddDamage(spaceDamage)
			elseif not Board:IsBlocked(p2, PATH_PROJECTILE) then
				ret:AddDamage(spaceDamage)

				local spawnSawblade = SpaceDamage(p2, 0)
				spawnSawblade.sPawn = self.SawbladePawn --doesn't preview the spawned unit
				ret:AddDamage(spawnSawblade)
			else
				ret:AddDamage(spaceDamage)
			end
		end

		--ret:AddDamage(spaceDamage)
	end

	--Doesn't seem to work?
	--ret:AddScript("missionData().lastLauncher = Pawn")

	return ret
end

local function DistFromLine(point, lineP1, lineP2)
	return 0 --tmp
end

local function GetLinePoints(p1, p2)
	LOGF("GetLinePoints(p1: %s, p2: %s)", p1:GetString(), p2:GetString())
	local linePoints = {}

	if p1.x == p2.x or p1.y == p2.y then
		LOG(" ----------- Aligned - A")
		--Aligned
		local dir = GetDirection(p2 - p1)
		for i = 0, p1:Manhattan(p2) do
			local curr = p1 + DIR_VECTORS[dir] * i
			table.insert(linePoints, curr)
		end
	else
		LOG(" ----------- Diagonal - A")
		local iMin = math.min(p1.x, p2.x)
		local iMax = math.max(p1.x, p2.x)

		local jMin = math.min(p1.y, p2.y)
		local jMax = math.max(p1.y, p2.y)

		--Line params
		local slope = (jMax - jMin) / (iMax - iMin)
		LOG("slope: "..tostring(slope))

		LOGF("iMin: %s, iMax: %s, jMin: %s, jMax: %s", tostring(iMin), tostring(iMax), tostring(jMin), tostring(jMax))

		for j = jMin, jMax do
			for i = iMin, iMax do
				local curr = Point(i, j)
				local dist = DistFromLine(curr, p1, p2)
				if dist <= 1 and curr ~= p1 and curr ~= p2 then
					LOG("---------- added: "..curr:GetString())
					table.insert(linePoints, curr)
				end
			end
		end

	end

	return linePoints
end

function truelch_SawbladeLauncher:ReturnSawblade(p1, p2)
	local ret = SkillEffect()

	--Projectile art (artillery) + self-damage
	local returnProj = SpaceDamage(p1, self.ReturnSelfDamage)
	ret:AddArtillery(p2, returnProj, self.ShotUpArt, NO_DELAY)

	--Line calculation (TODO)
	local line = GetLinePoints(p1, p2)
	for _, point in ipairs(line) do
		local damage = SpaceDamage(point, self.ReturnDamage)
		ret:AddDamage(damage)
	end

	--Add sawblade
	ret:AddScript("addSawBlade(Pawn)")

	return ret
end

function truelch_SawbladeLauncher:RebuildSawblade(p1, p2)
	local ret = SkillEffect()

	ret:AddScript("addSawBlade(Pawn)")

	return ret
end


function truelch_SawbladeLauncher:GetSkillEffect(p1, p2)
	local ret = SkillEffect() --tmp?

	local status = self:GetSawbladeStatus()

	LOG("truelch_SawbladeLauncher:GetSkillEffect -> status: "..tostring(status))

	if status == nil or status == -1 then --error!
		LOG(" ----------- return error")
		return ret --maybe we should attempt to rebuild the sawblade in that case?
	end

	if status == 0 then
		--sawblade is on the mech
		--LOG(" ----------- sawblade is on the mech")
		return self:LaunchSawblade(p1, p2)
	elseif status == 1 then
		--sawblade is dead
		--LOG(" ----------- sawblade is dead")
		return self:RebuildSawblade(p1, p2)
	else
		--sawblade is on the board and still alive!
		--in that case, status is actually the sawblade's id!
		--LOG(" ----------- sawblade is alive!")
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
	--LOG("EVENT_onMissionStarted")
	for i = 0, 2 do
		local mech = Board:GetPawn(i)

		--LOGF("[%s] mech: %s", tostring(i), mech:GetMechName())
		
		--Returns true if the pawn has powered a weapon of type weapon or a less powered variant of it. false otherwise.
		--just using mech:IsWeaponPowered("truelch_SawbladeLauncher_AB") did NOT work with base version, unlike what documentation described.
		if mech:IsWeaponPowered("truelch_SawbladeLauncher") or
				mech:IsWeaponPowered("truelch_SawbladeLauncher_A") or
				mech:IsWeaponPowered("truelch_SawbladeLauncher_B") or
				mech:IsWeaponPowered("truelch_SawbladeLauncher_AB") then --this should be the only one required but it didn't work for the base weapon
			--LOG(" -----> "..mech:GetMechName().." is equipped with a Sawblade launcher")
			addSawBlade(mech)
		else
			--LOG(" -----> not equipped with sawblade launcher")
		end
	end
end

local function EVENT_onPawnKilled(mission, pawn)
	if pawn == nil then return end

	if isSawbladePawn(pawn) then
		for i = 0, 2 do
			if missionData().sawStatus ~= nil and
					missionData().sawStatus[i] ~= nil and
					missionData().sawStatus[i] == pawn:GetId() then
				missionData().sawStatus[i] = 1 --dead
			end
		end
	end
end

local function EVENT_onSkillEnd(mission, pawn, weaponId, p1, p2)

    if type(weaponId) == 'table' then
        weaponId = weaponId.__Id
    end

	if weaponId == "truelch_SawbladeLauncher" or
			weaponId == "truelch_SawbladeLauncher_A" or
			weaponId == "truelch_SawbladeLauncher_B" or
			weaponId == "truelch_SawbladeLauncher_AB" then
		LOGF("---------- Launcher registered: %s, id: %s", pawn:GetMechName(), tostring(pawn:GetId()))

		--Do NOT attempt to save the pawn. Save the id instead for example
		--https://discord.com/channels/417639520507527189/418142041189646336/1335038444090691626
		--missionData().lastLauncher = pawn
		missionData().lastLauncher = pawn:GetId()
	end
end

local function EVENT_onPawnTracked(mission, pawn)
	if pawn == nil then
		LOG("pawn is nil! wtf")
		return
	end

	--local launcher = missionData().lastLauncher
	local launcherId = Board:GetPawn(missionData().lastLauncher)
	--[[
	if launcher ~= nil then
		LOGF("------------ last launching: %s, id: %s", launcher:GetMechName(), tostring(launcher:GetId()))
	else
		LOG("------------ launcher is nil!")
	end
	]]

	if isSawbladePawn(pawn) then
		--missionData().sawStatus[launcher:GetId()] = pawn:GetId()
		missionData().sawStatus[launcher] = pawn:GetId()
	end
end

modApi.events.onMissionStart:subscribe(EVENT_onMissionStarted)
modapiext.events.onPawnKilled:subscribe(EVENT_onPawnKilled)
modapiext.events.onSkillEnd:subscribe(EVENT_onSkillEnd)
modapiext.events.onPawnTracked:subscribe(EVENT_onPawnTracked)
