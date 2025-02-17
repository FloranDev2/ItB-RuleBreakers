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

	if mission.truelch_RuleBreakers.sawAmount == nil then
		mission.truelch_RuleBreakers.sawAmount = {}
	end

	return mission.truelch_RuleBreakers
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


function truelch_SawbladeLauncher:SetSawblade(value)
	if Pawn == nil then return end --should now happen

	local pawnId = Pawn:GetId()
	local oldValue = missionData().sawAmount[pawnId]

	--Update anims
	if oldValue == 0 and newValue == 1 then
		customAnim:add(pawnId, self.Anim)
	elseif oldValue == 1 and newValue == 0 then
		customAnim:rem(pawnId, self.Anim)
	end

	--Apply value

end


function truelch_SawbladeLauncher:AddSawblade(incr)
	if Pawn == nil then return end --should now happen

	local oldValue = missionData().sawAmount[pawn:GetId()]
	newValue = oldValue + incr

	--Limits
	if missionData().sawAmount[Pawn:GetId()] < 0 then
		missionData().sawAmount[Pawn:GetId()] = 0
	elseif missionData().sawAmount[Pawn:GetId()] > 1 then
		missionData().sawAmount[Pawn:GetId()] = 1
	end

	--Apply value
	truelch_setSawblade(Pawn, newValue)
end

function truelch_SawbladeLauncher:GetSawbladeAmount()
	if missionData().sawAmount[Pawn:GetId()] == nil then
		self:SetSawBlade(0)
	end
	return missionData().sawAmount[Pawn:GetId()]
end

function truelch_SawbladeLauncher:GetTargetArea_Normal(point)
	local ret = PointList()

	local amount = self:GetSawbladeAmount()
	--LOGF("truelch_SawbladeLauncher:GetTargetArea_Normal -> amount: %s", tostring(amount))

	if amount == 0 then
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
	elseif amount == 1 then
		for j = 0, 7 do
			for i = 0, 7 do
				local curr = Point(i, j)
				local pawn = Board:GetPawn(curr)
				if curr == point then --to reload
					ret:push_back(curr)
				elseif isSawbladePawn(pawn) then
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

function truelch_SawbladeLauncher:LaunchSawblade(p1, p2)
	local ret = SkillEffect()

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
			ret:AddDamage(spaceDamage)			
		end
	end

	--In any case, right?
	ret:AddScript("self:AddSawblade(Pawn, -1)")

	return ret
end

local function distancePointLine(px, py, x1, y1, x2, y2)
	local A = y2 - y1
	local B = x1 - x2
	local C = x2 * y1 - x1 * y2

	local distance = math.abs(A * px + B * py + C) / math.sqrt(A^2 + B^2)
	return distance
end

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
		local iMin = math.min(p1.x, p2.x)
		local iMax = math.max(p1.x, p2.x)

		local jMin = math.min(p1.y, p2.y)
		local jMax = math.max(p1.y, p2.y)

		for j = jMin, jMax do
			for i = iMin, iMax do
				local curr = Point(i, j)
				if curr ~= p1 and curr ~= p2 then					
					local dist = distancePointLine(curr.x, curr.y, p1.x, p1.y, p2.x, p2.y)
					local dmg = 0

					if dist <= 0.1 then
						dmg = 3
					elseif dist <= 0.5 then
						dmg = 2
					elseif dist <= 0.75 then
						dmg = 1
					end

					local damage = SpaceDamage(curr, dmg)
					ret:AddDamage(damage)
				end
			end
		end
	end
end

function truelch_SawbladeLauncher:ReturnSawblade(p1, p2)
	local ret = SkillEffect()

	local pawn = Board:GetPawn(p2)

	if not isSawbladePawn(pawn) then
		LOG("----------- WTF")
		return ret
	end

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

	--Push adjacent (Option?)
	for dir = DIR_START, DIR_END do
		local curr = p2 + DIR_VECTORS[dir]
		local damage = SpaceDamage(curr, 0)
		damage.sAnimation = "airpush_"..dir
		damage.iPush = dir
		ret:AddDamage(damage)
	end

	return ret
end

function truelch_SawbladeLauncher:GetSkillEffect_Normal(p1, p2)
	local ret = SkillEffect()
	local status = self:GetSawbladeAmount()

	if status == nil or status == -1 then --error!
		--[[
		LOG("----------- return error")
		return ret --maybe we should attempt to rebuild the sawblade in that case?
		]]
		LOG("status was nil or -1, let's put it to 0 to fix that")
		--Let's consider that the mech has no sawblade

		--truelch_addSawBlade(Pawn)
		--status = 0

	end

	LOGF("truelch_SawbladeLauncher:GetSkillEffect_Normal -> status: %s", tostring(status))

	if status == 0 then
		return self:LaunchSawblade(p1, p2)
	else
		local pawn = Board:GetPawn(p2)
		if p2 == p1 then
			return self:RebuildSawblade(p1, p2)
		elseif isSawbladePawn(pawn) then
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
		Board:AddAlert(p1, "Launch Sawblade")
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
			truelch_addSawBlade(mech)
		end
	end
end

local function EVENT_onMissionStarted(mission)
	initSawbladeLaunchers()
end

local function EVENT_onMissionNextPhaseCreated(prevMission, nextMission)
	initSawbladeLaunchers()
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
    if type(weaponId) == 'table' then weaponId = weaponId.__Id end

	if weaponId == "truelch_SawbladeLauncher" or
			weaponId == "truelch_SawbladeLauncher_A" or
			weaponId == "truelch_SawbladeLauncher_B" or
			weaponId == "truelch_SawbladeLauncher_AB" then
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
		--was putting sawblade's id before, but no longer needed, I think I could ditch that and put the status to 1 in the weapon's skill effect
		missionData().sawStatus[launcherId] = 1
	end
end


--If p2 was targeting a building and this building is destroyed by the sawblade launcher, spawns a sawblade!
local function EVENT_onBuildingDestroyed(mission, buildingData)
	LOG("Building at "..buildingData.loc:GetString().." was destroyed!")

	if buildingData.loc == p2 then
	end

end


modApi.events.onMissionStart:subscribe(EVENT_onMissionStarted)
modApi.events.onMissionNextPhaseCreated:subscribe(EVENT_onMissionNextPhaseCreated)
modapiext.events.onPawnKilled:subscribe(EVENT_onPawnKilled)
modapiext.events.onSkillEnd:subscribe(EVENT_onSkillEnd)
modapiext.events.onPawnTracked:subscribe(EVENT_onPawnTracked)
modapiext.events.onBuildingDestroyed:subscribe(EVENT_onBuildingDestroyed)