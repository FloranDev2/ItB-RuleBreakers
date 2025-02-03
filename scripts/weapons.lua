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
		LOG("------------------- sawStatus table initialized")
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

function truelch_addSawBlade(pawn)
	LOG("truelch_addSawBlade")
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
				--Set status: sawblade destroyed (since it's not actually deployed)
				ret:AddScript("missionData().sawStatus[Pawn:GetId()] = 1")
				--TODO: play anim?
			end
		end

		--ret:AddDamage(spaceDamage)
	end

	--Doesn't seem to work?
	--ret:AddScript("missionData().lastLauncher = Pawn:GetId()")

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


local function getLinePoints(p1, p2)
	LOGF("getLinePoints(p1: %s, p2: %s)", p1:GetString(), p2:GetString())
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

		LOGF("iMin: %s, iMax: %s, jMin: %s, jMax: %s", tostring(iMin), tostring(iMax), tostring(jMin), tostring(jMax))

		for j = jMin, jMax do
			for i = iMin, iMax do
				local curr = Point(i, j)
				LOG(" ----------- curr: "..curr:GetString())
				--local dist = DistFromLine(curr, p1, p2, iMin, iMax, jMin, jMax)
				local dist = distancePointLigne(curr.x, curr.y, p1.x, p1.y, p2.x, p2.y)
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
	local line = getLinePoints(p1, p2)
	for _, point in ipairs(line) do
		local damage = SpaceDamage(point, self.ReturnDamage)
		ret:AddDamage(damage)
	end

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

local function EVENT_onMissionStarted(mission)
	for i = 0, 2 do
		local mech = Board:GetPawn(i)
		
		--Returns true if the pawn has powered a weapon of type weapon or a less powered variant of it. false otherwise.
		--just using mech:IsWeaponPowered("truelch_SawbladeLauncher_AB") did NOT work with base version, unlike what documentation described.
		if mech ~= nil and
				(mech:IsWeaponPowered("truelch_SawbladeLauncher") or
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

	if isSawbladePawn(pawn) and missionData().lastLauncher ~= nil then
		local launcherId = missionData().lastLauncher
		missionData().sawStatus[launcherId] = pawn:GetId()
	end
end

modApi.events.onMissionStart:subscribe(EVENT_onMissionStarted)
modapiext.events.onPawnKilled:subscribe(EVENT_onPawnKilled)
modapiext.events.onSkillEnd:subscribe(EVENT_onSkillEnd)
modapiext.events.onPawnTracked:subscribe(EVENT_onPawnTracked)


-------------------
--- Grid Shield ---
-------------------

truelch_GridShield = Skill:new{
	--Infos
	Name = "Grid Shield",
	Description = "Teleport to a city within move range.\nShield the unit and the building.",
	Class = "Science",
	Icon = "/weapons/truelch_grid_shield.png",

	--Shop
	Rarity = 1,
	PowerCost = 0,
	
	Upgrades = 2,
	UpgradeCost = { 1, 1 },

	--Gameplay
	AutoShield = false, --only for tip image
	PushAdjacent = true,

	--Tip image
	TipImage = {
		Unit       = Point(2, 3),
		Building   = Point(2, 2),
		Building   = Point(2, 3),
		Enemy      = Point(2, 1),
		Target     = Point(2, 2),
		CustomPawn = "truelch_GridMech"
	}
}

modApi:addWeaponDrop("truelch_GridShield")

Weapon_Texts.truelch_GridShield_Upgrade1 = "Auto-shield"
Weapon_Texts.truelch_GridShield_Upgrade2 = "Explosive Shield"


truelch_GridShield_A = truelch_GridShield:new{
	UpgradeDescription = "Automatically gain a shield at round start.",
	AutoShield = true,
}

truelch_GridShield_B = truelch_GridShield:new{
	UpgradeDescription = "Deploying the shield pushes adjacent unit",
	PushAdjacent = true,
}

truelch_GridShield_AB = truelch_GridShield:new{
	AutoShield = true,
	PushAdjacent = true,
}

function truelch_GridShield:GetTargetArea(point)
	local ret = PointList()

	local moveSpeed = Pawn:GetMoveSpeed()

	--can target self?

	--yes, I'm lazy
	for j = 0, 7 do
		for i = 0, 7 do
			local curr = Point(i, j)
			if point:Manhattan(curr) <= moveSpeed then
				ret:push_back(curr)
			end
		end
	end
	
	return ret
end

function truelch_GridShield:GetSkillEffect(p1, p2)
	local ret = SkillEffect()

	ret:AddTeleport(p1, p2, FULL_DELAY)

	local shield = SpaceDamage(p2, 0)
	shield.iShield = 1
	ret:AddDamage(shield)

	if self.PushAdjacent then
		for dir = DIR_START, DIR_END do
			local curr = p2 + DIR_VECTORS[dir]
			local push = SpaceDamage(curr, 0)
			push.sAnimation = "airpush_"..dir
			push.iPush = dir
			ret:AddDamage(push)
		end
	end

	return ret
end

local function EVENT_onNextTurn(mission)
	for i = 0, 2 do
		local mech = Board:GetPawn(i)
		--only if the mech is on a building?
		if mech ~= nil and (mech:IsWeaponPowered("truelch_GridShield_A") or mech:IsWeaponPowered("truelch_GridShield_AB")) then
			mech:SetShield(true)
			Board:AddAlert(mech:GetSpace(), "Auto-Shield")
		end
	end
end

modApi.events.onNextTurn:subscribe(EVENT_onNextTurn)


----------------------
--- Grid Discharge ---
----------------------

truelch_GridDischarge = Skill:new{
	--Infos
	Name = "Grid Discharge",
	Description = "Deal damage equal to current grid power to an adjacent target.",
	Class = "Science",
	Icon = "weapons/truelch_grid_discharge",

	--Shop
	Rarity = 1,
	PowerCost = 0,
	
	Upgrades = 2,
	UpgradeCost = { 1, 1 },

	--Gameplay

	--Art
	Anim = "",

	--Tip image
	TipImage = {
		Unit       = Point(2, 2),
		Building   = Point(2, 2),
		Enemy      = Point(2, 1),
		Target     = Point(2, 1),
		CustomPawn = "truelch_GridMech"
	}
}

modApi:addWeaponDrop("truelch_GridDischarge")

Weapon_Texts.truelch_GridDischarge_Upgrade1 = "Auto-shield"
Weapon_Texts.truelch_GridDischarge_Upgrade2 = "Explosive Shield"

function truelch_GridDischarge:GetTargetArea(point)
	local ret = PointList()

	local moveSpeed = Pawn:GetMoveSpeed()

	--can target self?

	--yes, I'm lazy
	for j = 0, 7 do
		for i = 0, 7 do
			local curr = Point(i, j)
			if point:Manhattan(curr) <= moveSpeed then
				ret:push_back(curr)
			end
		end
	end
	
	return ret
end

function truelch_GridDischarge:GetSkillEffect(p1, p2)
	local ret = SkillEffect()

	local dmg = 2
	if Game ~= nil then
		dmg = Game:GetPower():GetValue()
	end

	local damage = SpaceDamage(p2, dmg)
	damage.sAnimation = "LightningBolt_Animated"
	ret:AddMelee(p1, damage)

	return ret
end


--------------------
--- Rift Inducer ---
--------------------

truelch_RiftInducer = Skill:new{
	--Infos
	Name = "Rift Inducer",
	Description = "Shoot a projectile opening a spatial rift at the target tile.",
	Class = "Ranged",
	Icon = "/weapons/truelch_rift_inducer.png",

	--Shop
	Rarity = 1,
	PowerCost = 0,
	
	Upgrades = 2,
	UpgradeCost = { 1, 2 },

	--Gameplay
	TwoClick = true,
	Damage = 0,
	SecondTargetRange = 1,
	Confuse = false,

	--Art
	UpShot = "advanced/effects/shotup_swapother.png",
	LaunchSound = "/weapons/force_swap",

	--Tip image
	TipImage = {
		Unit   = Point(2, 3),
		Enemy  = Point(2, 1),
		Enemy2 = Point(1, 1),
		Target = Point(2, 1),
		Second_Click = Point(1, 1),
		CustomPawn = "truelch_DislocationMech",
		--Queued1 = Point(2,2), --didn't know this was a thing
	}
}

modApi:addWeaponDrop("truelch_RiftInducer")

Weapon_Texts.truelch_RiftInducer_Upgrade1 = "+1 Range"
Weapon_Texts.truelch_RiftInducer_Upgrade2 = "Confusion"

truelch_RiftInducer_A = truelch_RiftInducer:new{
	UpgradeDescription = "Swap range increased by one.",
	SecondTargetRange = 2,
}

truelch_RiftInducer_B = truelch_RiftInducer:new{
	UpgradeDescription = "Confuse vek swapped by this weapon, flipping their attack direction.",
	Confuse = true,
}

truelch_RiftInducer_AB = truelch_RiftInducer:new{	
	SecondTargetRange = 2,
	Confuse = true,
}

function truelch_RiftInducer:GetTargetArea(point)
	local ret = PointList()

	for dir = DIR_START, DIR_END do
		for i = 2, 7 do
			local curr = point + DIR_VECTORS[dir] * i
			if Board:IsValid(curr) then
				ret:push_back(curr)
			end
		end
	end
	
	return ret
end

function truelch_RiftInducer:GetSkillEffect(p1, p2)
	local ret = SkillEffect()

	local damage = SpaceDamage(p2, self.Damage)
	if self.Confuse then
		damage = SpaceDamage(p2, self.Damage, DIR_FLIP)
	end

	--From Science_TC_SwapOther
	if not Board:IsPawnSpace(p2) then 
		damage.sImageMark = "advanced/combat/icons/icon_x_glow.png"
	elseif Board:GetPawn(p2):IsGuarding() then
		damage.sImageMark = "combat/icons/icon_guard_glow.png"
	else
		damage.sImageMark = "advanced/combat/icons/icon_teleport_glow.png"
	end

	ret:AddArtillery(damage, self.UpShot)

	return ret
end

function truelch_RiftInducer:GetSecondTargetArea(p1, p2)
	local ret = PointList()
	
	for dir = DIR_START, DIR_END do
		for i = 1, self.SecondTargetRange do
			local curr = p2 + DIR_VECTORS[dir] * i
			if Board:IsValid(curr) then
				ret:push_back(curr)
			end
		end
	end

	return ret
end

function truelch_RiftInducer:GetFinalEffect(p1, p2, p3)
	--local ret = self:GetSkillEffect(p1, p2)	
	local ret = SkillEffect()

	--[[
	local first_damage = SpaceDamage(p2, self.Damage)
	if self.Confuse then
		first_damage = SpaceDamage(p2, self.Damage, DIR_FLIP)
	end
	first_damage.bHidePath = true
	ret:AddArtillery(first_damage, self.UpShot, NO_DELAY)

	local second_damage = SpaceDamage(p3, self.Damage)
	if self.Confuse then
		second_damage = SpaceDamage(p3, self.Damage, DIR_FLIP)
	end
	second_damage.bHidePath = true
	ret:AddArtillery(second_damage, self.UpShot)

	local delay = Board:IsPawnSpace(p3) and 0 or FULL_DELAY
	ret:AddTeleport(p2, p3, delay)
	
	if delay ~= FULL_DELAY then
		ret:AddTeleport(p3, p2, FULL_DELAY)
	end
	]]

	--SWAP TILES!!!
	local tile2 = Board:GetTerrain(p2)
	local currHealth2 = Board:GetHealth(p2)
	local maxHealth2 = Board:GetHealth(p2)

	local tile3 = Board:GetTerrain(p3)
	local currHealth3 = Board:GetHealth(p3)
	local maxHealth3 = Board:GetHealth(p3)

	--rift_unit.png
	local riftAnim2 = SpaceDamage(p2, 0)
	--riftAnim2.sAnimation = "rift_unit"
	riftAnim2.sAnimation = "RiftUnit"
	--riftAnim2.sAnimation = "ExploAcid1"
	riftAnim2.sSound = "/weapons/swap"
	ret:AddDamage(riftAnim2)

	local riftAnim3 = SpaceDamage(p3, 0)
	riftAnim3.sAnimation = "rift_unit"
	--riftAnim3.sAnimation = "ExploAcid1"
	ret:AddDamage(riftAnim3)

	ret:AddScript(string.format("Board:SetTerrain(%s, %s)",    p2:GetString(), tostring(tile3)))
	ret:AddScript(string.format("Board:SetHealth(%s, %s, %s)", p2:GetString(), tostring(currHealth3), tostring(maxHealth3)))

	ret:AddScript(string.format("Board:SetTerrain(%s, %s)",    p3:GetString(), tostring(tile2)))
	ret:AddScript(string.format("Board:SetHealth(%s, %s, %s)", p3:GetString(), tostring(currHealth2), tostring(maxHealth2)))
	
	return ret
end