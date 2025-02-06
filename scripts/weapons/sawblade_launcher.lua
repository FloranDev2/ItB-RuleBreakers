local mod = mod_loader.mods[modApi.currentMod]

local path = mod_loader.mods[modApi.currentMod].scriptPath
local customAnim = require(path.."libs/customAnim")

local smoothedLine = true
modApi.events.onModLoaded:subscribe(function(id)
	if id ~= mod.id then return end
	local options = mod_loader.currentModContent[id].options
	smoothedLine = options["option_smoothed_line"].enabled
end)

local diagonalLaunch = false
modApi.events.onModLoaded:subscribe(function(id)
	if id ~= mod.id then return end
	local options = mod_loader.currentModContent[id].options
	diagonalLaunch = options["option_diagonal_launch"].enabled
end)

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
	if mission.truelch_RuleBreakers.sawStatus == nil then
		mission.truelch_RuleBreakers.sawStatus = {}
	end

	return mission.truelch_RuleBreakers
end

local function isVarNil(msg, var)
	if var == nil then
		LOG("----------- "..msg.." is nil :(")
	else
		LOG("----------- "..msg.." exists :)")
	end
end

local function debugSawStatus()
	LOG("debugSawStatus()")
	LOG("tostring(missionData().sawStatus)): "..tostring(missionData().sawStatus))
	--LOG("tostring(extract_table(missionData().sawStatus)): "..tostring(extract_table(missionData().sawStatus)))

	--Simpler attempt:
	for i = 0, 2 do
		if missionData().sawStatus[i] ~= nil then
			LOGF("missionData().sawStatus[%s] = %s", tostring(i), tostring(missionData().sawStatus[i]))
		else
			LOGF("missionData().sawStatus[%s] is nil!", tostring(i))
		end
	end
end

function truelch_addSawBlade(pawn)
	if pawn == nil then return end
	missionData().sawStatus[pawn:GetId()] = 0
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
	Icon = "weapons/truelch_sawblade_launcher.png",

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

	OnKill = "Spawn Sawblade",

	--Art
	ProjectileArt = "effects/shot_pierce",
	ShotUpArt = "advanced/effects/shotup_deploybomb.png",
	ArtilleryHeight = 0, --artillery arc

	--Tip image
	TipIndex = 0,
	TipImage = {
		Unit   = Point(2, 3),
		Enemy  = Point(2, 1),
		Enemy2 = Point(2, 0),

		Target = Point(2, 0),
		CustomPawn = "truelch_SawbladeMech",
		CustomEnemy = "Scarab1",
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

function truelch_SawbladeLauncher:GetTargetArea_Normal(point)
	local ret = PointList()

	local status = self:GetSawbladeStatus()

	if status == 0 or status == 1 then
		if diagonalLaunch then
			for j = -self.Range, self.Range do
				for i = -self.Range, self.Range do
					local curr = point + Point(i, j)
					if Board:IsValid(curr) then
						ret:push_back(curr)
					end
				end
			end
		else
			for dir = DIR_START, DIR_END do
				for i = 1, self.Range do
					local curr = point + DIR_VECTORS[dir]*i
					ret:push_back(curr)
				end
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

function truelch_SawbladeLauncher:GetTargetArea_TipImage(point)
	local ret = PointList()
	return ret
	--TODO
end

--What does the following do again?
--spaceDamage.bKO_Effect = true --??

-- mission().sawStatus
-- 0: Sawblade on the Mech
function truelch_SawbladeLauncher:GetTargetArea(point)
	if not Board:IsTipImage() then
		return self:GetTargetArea_Normal(point)
	else
		return self:GetTargetArea_TipImage(point)
	end
end

function truelch_SawbladeLauncher:LaunchSawblade(p1, p2)
	local ret = SkillEffect()

	--TODO: remove custom anim (in AddScript)

	local dir = GetDirection(p2 - p1)
	local dist = p1:Manhattan(p2)
	local currEscDmg = 0

	local projArt = SpaceDamage(p2, 0)
	ret:AddProjectile(projArt, self.ProjectileArt, NO_DELAY)

	for i = 1, dist do
		local curr = p1 + DIR_VECTORS[dir] * i
		local spaceDamage = SpaceDamage(curr, self.Damage + currEscDmg)

		ret:AddDelay(0.1)

		if Board:IsDeadly(spaceDamage, Pawn) then
			currEscDmg = currEscDmg + self.EscalatingDamage
		end

		local regular = true

		if curr == p2 then
			if Board:IsDeadly(spaceDamage, Pawn) then

				spaceDamage.sPawn = self.SawbladePawn
				ret:AddDamage(spaceDamage)
				regular = false
			elseif not Board:IsBlocked(p2, PATH_PROJECTILE) then
				ret:AddDamage(spaceDamage)

				local spawnSawblade = SpaceDamage(p2, 0)
				spawnSawblade.sPawn = self.SawbladePawn --doesn't preview the spawned unit
				ret:AddDamage(spawnSawblade)
				regular = false
			end
		end

		if regular then
			spaceDamage.sAnimation = "ExploRaining1"
			ret:AddDamage(spaceDamage)
			--Set status: sawblade destroyed (since it's not actually deployed)
			ret:AddScript("missionData().sawStatus[Pawn:GetId()] = 1")
			--TODO: play anim?
		end
	end

	return ret
end


-- Fonction pour calculer la distance entre un point (px, py) et une ligne définie par deux points (x1, y1) et (x2, y2)
local function distancePointLigne(px, py, x1, y1, x2, y2)
	-- Calcul des coefficients de la ligne
	local A = y2 - y1
	local B = x1 - x2
	local C = x2 * y1 - x1 * y2

	-- Calcul de la distance
	local distance = math.abs(A * px + B * py + C) / math.sqrt(A^2 + B^2)
	return distance
end

--[[
-- Exemple d'utilisation
local px, py = 3, 4 -- Coordonnées du point
local x1, y1 = 1, 1 -- Coordonnées du premier point de la ligne
local x2, y2 = 5, 1 -- Coordonnées du deuxième point de la ligne

local dist = distancePointLigne(px, py, x1, y1, x2, y2)
LOG("La distance entre le point et la ligne est: " .. dist)
]]


local function computeLine(ret, p1, p2)
	--LOGF("----------- computeLine(p1: %s, p2: %s)", p1:GetString(), p2:GetString())
	--local linePoints = {}

	if p1.x == p2.x or p1.y == p2.y then
		--LOG("----------- Aligned")
		--Aligned
		local dir = GetDirection(p1 - p2)
		for i = 1, p1:Manhattan(p2) - 1 do
			local curr = p2 + DIR_VECTORS[dir] * i
			LOG("curr: "..curr:GetString())
			--table.insert(linePoints, curr)

			local damage = SpaceDamage(curr, 3)
			ret:AddDamage(damage)
		end
	else
		--LOG("----------- Diagonal")
		local iMin = math.min(p1.x, p2.x)
		local iMax = math.max(p1.x, p2.x)

		local jMin = math.min(p1.y, p2.y)
		local jMax = math.max(p1.y, p2.y)

		--LOGF("iMin: %s, iMax: %s, jMin: %s, jMax: %s", tostring(iMin), tostring(iMax), tostring(jMin), tostring(jMax))

		for j = jMin, jMax do
			for i = iMin, iMax do
				local curr = Point(i, j)
				if curr ~= p1 and curr ~= p2 then
					
					--local dist = DistFromLine(curr, p1, p2, iMin, iMax, jMin, jMax)
					local dist = distancePointLigne(curr.x, curr.y, p1.x, p1.y, p2.x, p2.y)
					--LOG("----------- dist: "..tostring(dist))

					local dmg = 0

					if dist <= 0.1 then
						dmg = 3
					elseif dist <= 0.5 then
						dmg = 2
					elseif dist <= 0.75 then
						dmg = 1
					end

					--LOG(string.format("curr: %s, dist: %s -> dmg: %s", curr:GetString(), tostring(dist), tostring(dmg)))

					local damage = SpaceDamage(curr, dmg)
					ret:AddDamage(damage)

					--LOG("----------- END")

					--[[
					if dist <= 1 and curr ~= p1 and curr ~= p2 then
						table.insert(linePoints, curr)
					end
					]]
				end
			end
		end
	end
end

function truelch_SawbladeLauncher:ReturnSawblade(p1, p2)
	local ret = SkillEffect()

	--Projectile art (artillery) + self-damage
	local returnProj = SpaceDamage(p1, self.ReturnSelfDamage)
	ret:AddArtillery(p2, returnProj, self.ShotUpArt, NO_DELAY)

	--Line calculation (TODO)
	computeLine(ret, p1, p2)

	--Destroy sawblade
	local killSawblade = SpaceDamage(p2, DAMAGE_DEATH)
	--Need to do the "safe" damage to not damage terrain
	ret:AddDamage(killSawblade)

	--Add sawblade
	ret:AddScript("truelch_addSawBlade(Pawn)")

	return ret
end

function truelch_SawbladeLauncher:RebuildSawblade(p1, p2)
	local ret = SkillEffect()

	ret:AddScript("truelch_addSawBlade(Pawn)")

	return ret
end

function truelch_SawbladeLauncher:GetSkillEffect_Normal(p1, p2)
	local ret = SkillEffect()

	local status = self:GetSawbladeStatus()

	--LOG("truelch_SawbladeLauncher:GetSkillEffect -> status: "..tostring(status))

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
	return ret
end

function truelch_SawbladeLauncher:GetSkillEffect_TipImage(p1, p2)
	local ret = SkillEffect()
	return ret
	--TODO
end

function truelch_SawbladeLauncher:GetSkillEffect(p1, p2)
	if not Board:IsTipImage() then
		return self:GetSkillEffect_Normal(p1, p2)
	else
		return self:GetSkillEffect_TipImage(p1, p2)
	end
end

local function EVENT_onMissionStarted(mission)
	for i = 0, 2 do
		local mech = Board:GetPawn(i)
		
		--Returns true if the pawn has powered a weapon of type weapon or a less powered variant of it. false otherwise.
		--just using mech:IsWeaponPowered("truelch_SawbladeLauncher_AB") did NOT work with base version, unlike what documentation described.
		if mech ~= nil and (mech:IsWeaponPowered("truelch_SawbladeLauncher") or
				mech:IsWeaponPowered("truelch_SawbladeLauncher_A") or
				mech:IsWeaponPowered("truelch_SawbladeLauncher_B") or
				mech:IsWeaponPowered("truelch_SawbladeLauncher_AB")) then --this should be the only one required but it didn't work for the base weapon
			--LOG(" -----> "..mech:GetMechName().." is equipped with a Sawblade launcher")
			truelch_addSawBlade(mech)
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
		--LOGF("---------- Launcher registered: %s, id: %s", pawn:GetMechName(), tostring(pawn:GetId()))

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

	if isSawbladePawn(pawn) and missionData().lastLauncher ~= nil then
		local launcherId = missionData().lastLauncher
		missionData().sawStatus[launcherId] = pawn:GetId()
	end
end

modApi.events.onMissionStart:subscribe(EVENT_onMissionStarted)
modapiext.events.onPawnKilled:subscribe(EVENT_onPawnKilled)
modapiext.events.onSkillEnd:subscribe(EVENT_onSkillEnd)
modapiext.events.onPawnTracked:subscribe(EVENT_onPawnTracked)