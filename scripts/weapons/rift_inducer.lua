--[[
Stuff to check:
- Dam


- Train: OK!!
- Armored Train
  -> trains are fine BUT since they are multi tile, they can potentially be displaced in a way that the other part will be moved
     to an occupied tile.

- Old Bar is a problem

]]

--GetUniqueBuilding
--[[
str_battery1
]]

--[[
LOG(save_table(GetCurrentMission()))
["QueuedSpawns"]
]]

local mod = mod_loader.mods[modApi.currentMod]
local path = mod.scriptPath
local functions = require(path.."functions")


local riftPawnExceptions = {
	"Dam_Pawn",
	--"SatelliteRocket", --it's fine
}

local function isRiftExc(pawn)
	if pawn == nil then
		return false
	end

	for _, rEx in ipairs(riftPawnExceptions) do
		if pawn:GetType() == rEx then
			return true
		end
	end

	return false
end

--[[
Also exclude items? Or just pods?
]]
local function isLocOkForRift(point)
	--LOG("isLocOkForRift(point: "..point:GetString()..")")
	local item = Board:GetItem(point) --it's "" and not nil but let's do both
	local pawn = Board:GetPawn(point) --that's what I forgot

	local cond1 = Board:IsValid(point)
	local cond2 = (pawn == nil or not isRiftExc(pawn))
	local cond3 = (Board:GetUniqueBuilding(point) == nil or Board:GetUniqueBuilding(point) == "")
	local cond4 = (item == nil or item == "")
	local cond5 = not Board:IsPod(point)	

	local isOk = cond1 and cond2 and cond3 and cond4 and cond5

	--[[
	LOGF("cond1: %s, cond2: %s, cond3: %s, cond4: %s, cond5: %s -> isOk: %s",
		tostring(cond1), tostring(cond2), tostring(cond3), tostring(cond4), tostring(cond5), tostring(isOk))
	]]

	return isOk

	--[[
	return true and
		Board:IsValid(point) and
		(pawn == nil or not isRiftExc(pawn)) and
		(Board:GetUniqueBuilding(point) == nil or Board:GetUniqueBuilding(point) == "") and
		(item == nil or item == "") and
		not Board:IsPod(point)
	]]
end

truelch_RiftInducer = Skill:new{
	--Infos
	Name = "Rift Inducer",
	Description = "Shoot a projectile opening a spatial rift at the target tile.\nCannot target special buildings, dams and time pods.",
	Class = "Ranged",
	Icon = "weapons/truelch_rift_inducer.png",

	--Shop
	Rarity = 1,
	PowerCost = 1, --nerf for 0.0.7
	
	Upgrades = 2,
	UpgradeCost = { 1, 2 },

	--Decision
	SwapGuard = true, --todo
	SwapSmoke = false,

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
		Unit     = Point(2, 3),
		Enemy1   = Point(2, 1),
		Queued1  = Point(1, 1),
		Building = Point(1, 1),
		Target   = Point(2, 1),
		Second_Click = Point(1, 1),
		CustomPawn = "truelch_DislocationMech",
	}
}

modApi:addWeaponDrop("truelch_RiftInducer")

Weapon_Texts.truelch_RiftInducer_Upgrade1 = "+1 Range"
Weapon_Texts.truelch_RiftInducer_Upgrade2 = "Confusion"

truelch_RiftInducer_A = truelch_RiftInducer:new{
	UpgradeDescription = "Swap range increased by one.",
	SecondTargetRange = 2,

	TipImage = {
		Unit     = Point(2, 3),
		Enemy1   = Point(2, 1),
		Queued1  = Point(0, 1),
		Building = Point(0, 1),
		Target   = Point(2, 1),
		Second_Click = Point(0, 1),
		CustomEnemy = "Scarab1",
		CustomPawn = "truelch_DislocationMech"
	}
}

truelch_RiftInducer_B = truelch_RiftInducer:new{
	UpgradeDescription = "Confuse vek swapped by this weapon, flipping their attack direction.",
	Confuse = true,

	TipImage = {
		Unit     = Point(2, 3),
		Enemy1   = Point(2, 1),
		Enemy2   = Point(3, 0),
		Queued1  = Point(1, 1),
		Building = Point(1, 1),

		Target       = Point(2, 1),
		Second_Click = Point(2, 0),
		CustomPawn = "truelch_DislocationMech"
	}
}

truelch_RiftInducer_AB = truelch_RiftInducer:new{	
	SecondTargetRange = 2,
	Confuse = true,

	TipImage = {
		Unit     = Point(2, 4),
		Enemy1   = Point(2, 2),
		Enemy2   = Point(3, 0),
		Queued1  = Point(1, 2),
		Building = Point(1, 2),

		Target       = Point(2, 2),
		Second_Click = Point(2, 0),
		CustomPawn = "truelch_DislocationMech"
	}
}

function truelch_RiftInducer:GetTargetArea(point)
	local ret = PointList()

	for dir = DIR_START, DIR_END do
		for i = 2, 7 do
			local curr = point + DIR_VECTORS[dir] * i
			local pawn = Board:GetPawn(curr)
			if isLocOkForRift(curr) then
				ret:push_back(curr)
			end
		end
	end
	
	return ret
end

function truelch_RiftInducer:GetSecAreaPoints(p2)
	local points = {}

	for j = 0, 7 do
		for i = 0, 7 do
			local curr = Point(i, j)
			local dist = p2:Manhattan(curr)
			if isLocOkForRift(curr) and dist <= self.SecondTargetRange and dist > 0 then
				points[#points + 1] = curr
			end 
		end
	end

	return points
end

function truelch_RiftInducer:GetSkillEffect(p1, p2)
	local ret = SkillEffect()

	local damage = SpaceDamage(p2, self.Damage)
	if self.Confuse then
		damage = SpaceDamage(p2, self.Damage, DIR_FLIP)
	end

	damage.sImageMark = "advanced/combat/icons/icon_teleport_glow.png"

	--Preview impossible
	for _, curr in pairs(self:GetSecAreaPoints(p2)) do
		if not isLocOkForRift(p2) then
			local damage = SpaceDamage(curr, 0)
			damage.sImageMark = "combat/icons/icon_swap_impossible.png"
			ret:AddDamage(damage)
		end
	end

	ret:AddArtillery(damage, self.UpShot)

	return ret
end

function truelch_RiftInducer:GetSecondTargetArea(p1, p2)
	local ret = PointList()

	for _, curr in pairs(self:GetSecAreaPoints(p2)) do
		ret:push_back(curr)
	end

	return ret
end

function truelch_RiftInducer:GetFinalEffect(p1, p2, p3)
	--local ret = self:GetSkillEffect(p1, p2)
	local ret = SkillEffect() --we want to ditch previous stuff, they were just for preview

	--ARTILLERY SHOTS
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
	
	return ret
end

local function findTempPoint(otherPoint)
	for j = 0, 7 do
		for i = 0, 7 do
			local curr = Point(i, j)
			if otherPoint ~= curr
					and not Board:IsBlocked(curr, PATH_PROJECTILE)
	                and not Board:IsPod(curr)
	                and not Board:IsTerrain(curr, TERRAIN_HOLE)
	                and not Board:IsTerrain(curr, TERRAIN_WATER) --works with lava? and acid water?
	                and not Board:IsTerrain(curr, TERRAIN_LAVA)
	                and not Board:IsAcid(curr)
	                and not Board:IsFire(curr) then
                return curr
            end
		end
	end

	LOG("Couldn't find a temporary point! Not an issue unless you target a Grid Mech lol")
	return Point(-1, -1)
end

local function EVENT_onFinalEffectEnd(mission, pawn, weaponId, p1, p2, p3)
	if type(weaponId) == 'table' then weaponId = weaponId.__Id end

	if weaponId ~= "truelch_RiftInducer" and weaponId ~= "truelch_RiftInducer_A"
		and weaponId ~= "truelch_RiftInducer_B" and weaponId ~= "truelch_RiftInducer_AB" then return end

	---- MOVE UNITS TO (-1, -1) ----
	local pawn2 = Board:GetPawn(p2)
	local pawn3 = Board:GetPawn(p3)

	--this doesn't fix the issue with swapping the Grid Mech *sigh*
	local tmp2 = findTempPoint(p2) --just to pass a point
	local tmp3 = findTempPoint(tmp2)

	--If I use SetSpace instead of AddTeleport:
	-- - GridMech teleport will crash the game (for the second teleport)
	-- - Enemies will either cancel their attack (when moved in (-1, -1))
	--   or will try to continue to attack the same tile
	--   which can either cancel their attack or just not move their relative attack pos with the relative move
	--   (scarab will attack the same tile even after being teleported one tile behind for example)

	if pawn2 ~= nil then
		--pawn2:SetSpace(Point(-1, -1))
		--pawn2:SetSpace(tmp2)
		local tpEffect = SkillEffect()
		tpEffect:AddTeleport(p2, tmp2, NO_DELAY)
		Board:AddEffect(tpEffect)
	end

	if pawn3 ~= nil then
		--pawn3:SetSpace(Point(-1, -1))
		--pawn3:SetSpace(tmp3)
		local tpEffect = SkillEffect()
		tpEffect:AddTeleport(p3, tmp3, NO_DELAY)
		Board:AddEffect(tpEffect)
	end

	---- SPAWN SWAP ----
	local spawn2 = mission:GetSpawnPointData(p2)
	local spawn3 = mission:GetSpawnPointData(p3)

	if spawn2 ~= nil and spawn3 == nil then
		mission:MoveSpawnPoint(p2, p3)

	elseif spawn3 ~= nil and spawn2 == nil then
		mission:MoveSpawnPoint(p3, p2)
	end

	---- REGISTER DATA ----
	local tile2 = Board:GetTerrain(p2)
	local currHealth2 = Board:GetHealth(p2)
	local maxHealth2 = Board:GetMaxHealth(p2)
	--shield, acid, smoke, fire, frozen, crack, ???
	local shield2 = Board:IsShield(p2)
	local acid2   = Board:IsAcid(p2)
	local smoke2  = Board:IsSmoke(p2)
	local fire2   = Board:IsFire(p2)
	local crack2  = Board:IsCracked(p2)

	local tile3 = Board:GetTerrain(p3)
	local currHealth3 = Board:GetHealth(p3)
	local maxHealth3 = Board:GetMaxHealth(p3)
	--shield, acid, smoke, fire, frozen, crack, ???
	local shield3 = Board:IsShield(p3)
	local acid3   = Board:IsAcid(p3)
	local smoke3  = Board:IsSmoke(p3)
	local fire3   = Board:IsFire(p3)
	local crack3  = Board:IsCracked(p3) --doesn't work with Damaged Ice or Damaged Mountains

	---- REMOVE EFFECTS (ACID, SHIELD, FIRE, SMOKE, ...) ----
	if not shield2 then
		Board:SetShield(p3, false)
	end
	if not shield3 then
		Board:SetShield(p2, false)
	end

	if not acid2 then
		Board:SetAcid(p3, false)
	end
	if not acid3 then
		Board:SetAcid(p2, false)
	end

	if not fire2 then
		Board:SetFire(p3, false)
	end
	if not fire3 then
		Board:SetFire(p2, false)
	end

	if not smoke2 then
		--1st bool argument (false) remove smoke.
		--Regardless of the second bool argument, the smoke disappears instantly
		Board:SetSmoke(p3, false, false)
	end
	if not smoke3 then
		Board:SetSmoke(p2, false, false)
	end

	--Problem: removing crack from cracked frozen water will not revert it to frozen water but to regular water
	--I'll comment that part temporarily...
	if crack2 and not crack3 then
		local uncrackEffect = SkillEffect()
		uncrackEffect:AddScript(string.format("Board:SetCracked(%s, false)", p2:GetString()))
		Board:AddEffect(uncrackEffect)
	end
	if crack3 and not crack2 then
		local uncrackEffect = SkillEffect()
		uncrackEffect:AddScript(string.format("Board:SetCracked(%s, false)", p3:GetString()))
		Board:AddEffect(uncrackEffect)
	end

	---- CHANGE TERRAIN EFFECT ----
	local changeTerrainEffect = SkillEffect()

	---- CHANGE TO ROAD ----
	if tile3 == TERRAIN_BUILDING then
		local damage = SpaceDamage(p2, 0)
		damage.iTerrain = TERRAIN_ROAD
		changeTerrainEffect:AddDamage(damage)
	else
		Board:SetTerrain(p2, tile3)
	end

	if tile2 == TERRAIN_BUILDING then
		local damage = SpaceDamage(p3, 0)
		damage.iTerrain = TERRAIN_ROAD
		changeTerrainEffect:AddDamage(damage)
	else
		Board:SetTerrain(p3, tile2)
	end

	---- DELAY ----
	changeTerrainEffect:AddDelay(0.1)

	---- CHANGE TO BUILDING ----
	if tile3 == TERRAIN_BUILDING then
		local damage = SpaceDamage(p2, 0)
		damage.iTerrain = TERRAIN_BUILDING
		changeTerrainEffect:AddDamage(damage)
	else
		--Nothing to do?
	end

	if tile2 == TERRAIN_BUILDING then
		local damage = SpaceDamage(p3, 0)
		damage.iTerrain = TERRAIN_BUILDING
		changeTerrainEffect:AddDamage(damage)
	else
		--Nothing to do?
	end

	---- ADD TERRAIN EFFECT ----
	Board:AddEffect(changeTerrainEffect)
	
	---- SET HEALTH EFFECT ----
	modApi:scheduleHook(550, function()
		local healthEffect = SkillEffect()
		healthEffect:AddScript(string.format("Board:SetHealth(%s, %s, %s)", p2:GetString(), tostring(currHealth3), tostring(maxHealth3)))
		healthEffect:AddScript(string.format("Board:SetHealth(%s, %s, %s)", p3:GetString(), tostring(currHealth2), tostring(maxHealth2)))
		Board:AddEffect(healthEffect)
	end)

	---- NEW: RELOCATE UNITS ----
	if pawn2 ~= nil then
		--pawn2:SetSpace(p3)
		local tpEffect = SkillEffect()
		tpEffect:AddTeleport(tmp2, p3, NO_DELAY)
		Board:AddEffect(tpEffect)
	end

	if pawn3 ~= nil then
		--pawn3:SetSpace(p2)
		local tpEffect = SkillEffect()
		tpEffect:AddTeleport(tmp3, p2, NO_DELAY)
		Board:AddEffect(tpEffect)
	end

	---- ADD STATUS (ACID, SHIELD, FIRE, SMOKE, ...) ----
	if shield2 then
		Board:AddShield(p3)
	end
	if shield3 then
		Board:AddShield(p2)
	end

	if acid2 then
		Board:SetAcid(p3, true)
	end
	if acid3 then
		Board:SetAcid(p2, true)
	end

	if fire2 then
		Board:SetFire(p3, true)
	end
	if fire3 then
		Board:SetFire(p2, true)
	end

	if smoke2 then
		--true, false: smoke appears with an animation
		--true, true: smoke appears instantly
		Board:SetSmoke(p3, true, false)
	end
	if smoke3 then
		Board:SetSmoke(p2, true, false)
	end

	if crack2 and not crack3 then
		Board:SetCracked(p3, true)
	end
	if crack3 and not crack2 then
		Board:SetCracked(p2, true)
	end
end

modapiext.events.onFinalEffectEnd:subscribe(EVENT_onFinalEffectEnd)