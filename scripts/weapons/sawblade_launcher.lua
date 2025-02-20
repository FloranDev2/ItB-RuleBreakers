---------------
--- IMPORTS ---
---------------

local mod = mod_loader.mods[modApi.currentMod]
local path = mod.scriptPath
local functions = require(path.."functions")


---------------
--- OPTIONS ---
---------------

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


--------------
--- WEAPON ---
--------------

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
	--Damage = 2, --old
	LaunchDmgData = { { 0.6, 2 } }, --[1] dist / [2] dmg
	LaunchDmgDataSmoothed = { { 0.4, 2 }, { 0.75, 1 } }, --[1] dist / [2] dmg

	--ReturnDamage = 3, --old
	ReturnDmgData = { { 0.6, 3 } },
	ReturnDmgDataSmoothed = { { 0.1, 3 }, { 0.5, 2 }, { 0.75, 1 } },

	EscalatingDamage = 0,
	Range = 4,
	SawbladePawn = "truelch_Sawblade",

	ReturnSelfDamage = 1,

	OnKill = "Spawn Sawblade",

	--Art
	ProjectileArt = "effects/truelch_sawblade_proj",
	ShotUpArt = "effects/truelch_shotup_sawblade.png",
	ArtilleryHeight = 0, --artillery arc
	Anim = "truelch_anim_sawblade",

	--Tip image
	TipIndex = 0,
	TipImage = {
		Unit   = Point(2, 3),
		Enemy  = Point(2, 1),
		Enemy2 = Point(2, 0),

		Friendly = Point(0, 0),

		Target = Point(2, 0),
		CustomPawn = "truelch_SawbladeMech",
		--CustomPawn = "truelch_Sawblade", --need to find something else to customize friendlies
		CustomEnemy = "Scarab1",
	}
}

modApi:addWeaponDrop("truelch_SawbladeLauncher")

Weapon_Texts.truelch_SawbladeLauncher_Upgrade1 = "Reinforced Sawblade"
Weapon_Texts.truelch_SawbladeLauncher_Upgrade2 = "Escalating Damage"

truelch_SawbladeLauncher_A = truelch_SawbladeLauncher:new{
	UpgradeDescription = "The sawblade gets +2 hp and +1 Thorns damage.",
	SawbladePawn = "truelch_Sawblade_A",
	Anim = "truelch_anim_sawblade_A",
}

truelch_SawbladeLauncher_B = truelch_SawbladeLauncher:new{
	UpgradeDescription = "+1 Damage for each unit killed.",
	EscalatingDamage = 1,
}

truelch_SawbladeLauncher_AB = truelch_SawbladeLauncher:new{
	SawbladePawn = "truelch_Sawblade_A",
	Anim = "truelch_anim_sawblade_A",
	EscalatingDamage = 1,
}

function truelch_SawbladeLauncher:GetTargetArea_Normal(point)
	local ret = PointList()

	local amount = functions:getSawbladeAmount(Pawn)

	if amount == 0 then
		--No sawblade on the Mech
		--either target a deployed sawblade to return
		--or self target to reload
		for j = 0, 7 do
			for i = 0, 7 do
				local curr = Point(i, j)
				if curr == point then --to reload
					ret:push_back(curr)
				elseif functions:isSawbladePos(curr) or functions:isReinforcedSawbladePos(curr) then
					ret:push_back(curr)
				end
			end
		end
	elseif amount >= 1 then
		--There's (at least) one sawblade on the Mech
		if diagonalLaunch then
			--Square area
			for j = -self.Range, self.Range do
				for i = -self.Range, self.Range do
					local curr = point + Point(i, j)
					if Board:IsValid(curr) and curr ~= point then
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
	end
	
	return ret
end

function truelch_SawbladeLauncher:GetTargetArea_TipImage(point)
	local ret = PointList()

	for j = 0, 7 do
		for i = 0, 7 do
			local curr = Point(i, j)
			ret:push_back(curr)
		end
	end

	return ret
end

function truelch_SawbladeLauncher:GetTargetArea(point)
	if not Board:IsTipImage() then
		return self:GetTargetArea_Normal(point)
	else
		return self:GetTargetArea_TipImage(point)
	end
end

local function distancePointLine(px, py, x1, y1, x2, y2)
	local A = y2 - y1
	local B = x1 - x2
	local C = x2 * y1 - x1 * y2

	local distance = math.abs(A * px + B * py + C) / math.sqrt(A^2 + B^2)
	return distance
end

--TODO: make it usable for both launch and return
--Also give a list of dist / damage
function truelch_SawbladeLauncher:ComputeLine(ret, p1, p2, dmgData, currEscDmg)
	if p1.x == p2.x or p1.y == p2.y then
		--Aligned
		local dir = GetDirection(p1 - p2)
		for i = 1, p1:Manhattan(p2) - 1 do
			local curr = p2 + DIR_VECTORS[dir] * i
			local damage = SpaceDamage(curr, 3)
			ret:AddDamage(damage)
		end
	else
		local iMin = math.min(p1.x, p2.x)
		local iMax = math.max(p1.x, p2.x)

		local jMin = math.min(p1.y, p2.y)
		local jMax = math.max(p1.y, p2.y)

		local iterations = 0

		local sortedDamageList = {} --[1] distFromStart [2] point [3] damage

		LOG("First loop")
		for j = jMin, jMax do
			for i = iMin, iMax do
				iterations = iterations + 1
				if iterations > 100 then
					LOG("if iterations > 100 then -> RETURN")
					return
				end
				local curr = Point(i, j)
				if curr ~= p1 and curr ~= p2 then					
					local distFromLine = distancePointLine(curr.x, curr.y, p1.x, p1.y, p2.x, p2.y)
					local distFromStart = math.sqrt((curr.x - p1.x)^2 + (curr.y - p1.y)^2) --for sorting
					local dmg = 0

					--Compute the damage (depending on the distance)
					for _, data in pairs(dmgData) do
						local distMax = data[1]
						local dmgVal  = data[2]

						if distFromLine <= distMax then
							dmg = dmgVal
							break
						end
					end

					if dmg > 0 then
						sortData = { distFromStart, curr, dmg }

						--Look through all existing damage and check distance
						local hasBeenInserted = false

						local it2 = 0
						for index, sDmg in pairs(sortedDamageList) do
							it2 = it2 + 1
							if it2 > 1000 then
								LOG("if it2 > 1000 then -> RETURN")
								return
							end
							--[1] distFromStart [2] point [3] damage
							if distFromStart < sDmg[1] then
								LOG("if distFromStart < sDmg[1]")
								hasBeenInserted = true
								table.insert(sortedDamageList, index, sortData)								
								break
							end
						end

						if not hasBeenInserted then
							LOG("if not hasBeenInserted then")
							sortedDamageList[#sortedDamageList + 1] = sortData
						end

					end					
				end
			end
		end

		LOG("Second loop: Escalating damage")
		--Second loop: Escalating damage
		--Need to compute damage closer from start (p1)
		--Because of escalating damage calculation
		for _, sDmg in pairs(sortedDamageList) do
			--[1] distFromStart [2] point [3] damage
			local distFromStart = sDmg[1]
			local pos    = sDmg[2]
			local dmgVal = sDmg[3]
			local spaceDamage = SpaceDamage(pos, dmgVal)
			if Board:IsDeadly(spaceDamage, Pawn) then
				currEscDmg = currEscDmg + self.EscalatingDamage
			end
		end

		LOG("Third loop: apply damage")
		--Third loop: apply damage
		for _, sDmg in pairs(sortedDamageList) do
			--local distFromStart = sDmg[1] --unused
			local pos    = sDmg[2]
			local dmgVal = sDmg[3]
			local spaceDamage = SpaceDamage(pos, dmgVal)
			ret:AddDamage(spaceDamage)
		end
	end

	return currEscDmg
end

function truelch_SawbladeLauncher:LaunchSawblade(p1, p2)
	LOGF("truelch_SawbladeLauncher:LaunchSawblade(p1: %s, p2: %s)", p1:GetString(), p2:GetString())

	local ret = SkillEffect()

	local dist = p1:Manhattan(p2)
	local currEscDmg = 0

	--local projArt = SpaceDamage(p2, 0)
	--ret:AddProjectile(projArt, self.ProjectileArt, NO_DELAY)
	local proj = SpaceDamage(p1, 0)
	ret:AddArtillery(p2, proj, self.ShotUpArt, NO_DELAY)

	if diagonalLaunch then
		if smoothedLine then
			currEscDmg = self:ComputeLine(ret, p1, p2, self.LaunchDmgDataSmoothed, currEscDmg)
		else
			currEscDmg = self:ComputeLine(ret, p1, p2, self.LaunchDmgData, currEscDmg)
		end
	end

	--P2 compute
	local endDamage = SpaceDamage(p2, 2 + currEscDmg)
	if Board:IsDeadly(endDamage, Pawn) then
		endDamage.sPawn = self.SawbladePawn
		ret:AddDamage(endDamage)
		regular = false
	elseif not Board:IsBlocked(p2, PATH_PROJECTILE) then
		endDamage.sPawn = self.SawbladePawn
		ret:AddDamage(endDamage)
		regular = false
	end

	if regular then
		ret:AddDamage(endDamage)
	end

	--Decrement sawblade by 1
	if not Board:IsTipImage() then
		ret:AddScript("truelch_addSawblade(Pawn, -1)")
	end
	return ret
end

function truelch_SawbladeLauncher:ReturnSawblade(p1, p2)
	local ret = SkillEffect()

	if not functions:isSawbladePos(p2) and not functions:isReinforcedSawbladePos(p2) then
		LOG("----------- WTF")
		return ret
	end

	--Projectile art (artillery) + self-damage
	local returnProj = SpaceDamage(p1, self.ReturnSelfDamage)
	ret:AddArtillery(p2, returnProj, self.ShotUpArt, NO_DELAY)

	local currEscDmg = 0

	if smoothedLine then
		currEscDmg = self:ComputeLine(ret, p1, p2, self.ReturnDmgDataSmoothed, currEscDmg)
	else
		currEscDmg = self:ComputeLine(ret, p1, p2, self.ReturnDmgData, currEscDmg)
	end

	--Destroy sawblade
	local killSawblade = SpaceDamage(p2, DAMAGE_DEATH)
	--Need to do the "safe" damage to not damage terrain
	ret:AddDamage(killSawblade)

	--Add sawblade
	if not Board:IsTipImage() then
		ret:AddScript("functions:addSawBlade(Pawn, 1)")
	end

	return ret
end

function truelch_SawbladeLauncher:RebuildSawblade(p1, p2)
	local ret = SkillEffect()

	ret:AddScript("functions:addSawBlade(Pawn, 1)")

	--Push adjacent (Option?)
	--[[
	for dir = DIR_START, DIR_END do
		local curr = p2 + DIR_VECTORS[dir]
		local damage = SpaceDamage(curr, 0)
		damage.sAnimation = "airpush_"..dir
		damage.iPush = dir
		ret:AddDamage(damage)
	end
	]]

	return ret
end

function truelch_SawbladeLauncher:GetSkillEffect_Normal(p1, p2)
	local ret = SkillEffect()
	local amount = functions:getSawbladeAmount(Pawn)

	if amount == nil or amount == -1 then
		functions:setSawblade(Pawn, 0)
		amount = 0
	end

	if amount >= 1 then
		return self:LaunchSawblade(p1, p2)
	else
		local pawn = Board:GetPawn(p2)
		if p2 == p1 then
			return self:RebuildSawblade(p1, p2)
		elseif functions:isSawbladePos(p2) or functions:isReinforcedSawbladePos(p2) then
			return self:ReturnSawblade(p1, p2)
		else
			LOG("----------- WTF")
		end
	end

	return ret
end

function truelch_SawbladeLauncher:GetSkillEffect_TipImage(p1, p2)
	local ret = SkillEffect()

	if self.TipIndex == 0 then
		--Launch sawblade
		Board:AddAlert(p1, "Launch Sawblade")
		self.TipIndex = 1
		return self:LaunchSawblade(p1, p2)

	elseif self.TipIndex == 1 then
		--Return sawblade
		--Spawn sawblade at p2

		Board:AddAlert(p1, "Return Sawblade")
		self.TipIndex = 0
		return self:ReturnSawblade(p1, p2)

	--elseif self.TipIndex == 2 then
	end

	return ret
end

function truelch_SawbladeLauncher:GetSkillEffect(p1, p2)
	if not Board:IsTipImage() then
		return self:GetSkillEffect_Normal(p1, p2)
	else
		return self:GetSkillEffect_TipImage(p1, p2)
	end
end

local function initSawbladeLaunchers()
	for i = 0, 2 do
		local mech = Board:GetPawn(i)
		if mech ~= nil and (mech:IsWeaponPowered("truelch_SawbladeLauncher") or
				mech:IsWeaponPowered("truelch_SawbladeLauncher_A") or
				mech:IsWeaponPowered("truelch_SawbladeLauncher_B") or
				mech:IsWeaponPowered("truelch_SawbladeLauncher_AB")) then
			functions:setSawblade(mech, 1)
		end
	end
end

local initFlag = false

local function EVENT_onMissionStarted(mission)
	--initSawbladeLaunchers()
	initFlag = true
end

local function EVENT_onMissionNextPhaseCreated(prevMission, nextMission)
	--initSawbladeLaunchers()
	initFlag = true
end

local EVENT_onNextTurn = function(mission)
	--LOG("Currently it is turn of team: " .. Game:GetTeamTurn())

	--During enemy turn to make it less noticeable?
	--Or during player's turn so he can aknowledge it and have a board alert?
	if initFlag == true then
		initFlag = false
		initSawbladeLaunchers()
	end
end

local function EVENT_onSkillEnd(mission, pawn, weaponId, p1, p2)
    if not functions:isMission() then return end

	if type(weaponId) == 'table' then weaponId = weaponId.__Id end

	if weaponId == "truelch_SawbladeLauncher" or
			weaponId == "truelch_SawbladeLauncher_A" or
			weaponId == "truelch_SawbladeLauncher_B" or
			weaponId == "truelch_SawbladeLauncher_AB" then
		functions:missionData().lastLauncherId = pawn:GetId()
		functions:missionData().sawLaunchTgt = p2
	else
		functions:missionData().sawLaunchTgt = nil
	end
end

--If p2 was targeting a building and this building is destroyed by the sawblade launcher, spawns a sawblade!
local function EVENT_onBuildingDestroyed(mission, buildingData)
	--LOG("Building at "..buildingData.loc:GetString().." was destroyed!")
	if functions:missionData().sawLaunchTgt ~= nil and buildingData.loc == functions:missionData().sawLaunchTgt then
		local launcher = Board:GetPawn(functions:missionData().lastLauncherId)
		if launcher ~= nil then
			if launcher:IsWeaponPowered("truelch_SawbladeLauncher") or launcher:IsWeaponPowered("truelch_SawbladeLauncher_B") then
				--Normal sawblade
				local spawnSawblade = SpaceDamage(buildingData.loc, 0)
				spawnSawblade.sPawn = "truelch_Sawblade"
				Board:AddEffect(spawnSawblade)
			elseif launcher:IsWeaponPowered("truelch_SawbladeLauncher_A") or launcher:IsWeaponPowered("truelch_SawbladeLauncher_AB") then
				--Reinforced sawblade
				local spawnSawblade = SpaceDamage(buildingData.loc, 0)
				spawnSawblade.sPawn = "truelch_Sawblade_A"
				Board:AddEffect(spawnSawblade)
			end
		end
	end
end

modApi.events.onMissionStart:subscribe(EVENT_onMissionStarted)
modApi.events.onMissionNextPhaseCreated:subscribe(EVENT_onMissionNextPhaseCreated)
modApi.events.onNextTurn:subscribe(EVENT_onNextTurn)
modapiext.events.onSkillEnd:subscribe(EVENT_onSkillEnd)
modapiext.events.onBuildingDestroyed:subscribe(EVENT_onBuildingDestroyed)