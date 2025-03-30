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
	--LOG("isRiftExc?...")
	if pawn == nil then
		--LOG("... RETURN")
		return false
	end

	--LOG("... pawn: "..pawn:GetType())

	for _, rEx in ipairs(riftPawnExceptions) do
		--LOGF("rEx: %s, pawn type: %s", rEx, pawn:GetType())
		if pawn:GetType() == rEx then
			--LOG("rift pawn exception: "..pawn:GetType())
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

	--LOGF("truelch_RiftInducer:GetTargetArea(point: %s)", point:GetString())

	for dir = DIR_START, DIR_END do
		for i = 2, 7 do
			local curr = point + DIR_VECTORS[dir] * i
			local pawn = Board:GetPawn(curr)

			if isLocOkForRift(curr) then
				ret:push_back(curr)
				--LOGF(" -> added: %s", curr:GetString())
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

--[[
pA might not even be needed after all...

pA = p2 and pB = p3
or
pA = p3 and pB = p2
]]
function truelch_RiftInducer:ComputeTile(ret, damage, pA, pB)
	if Board:IsAcid(pB) then
		--damage.iAcid = EFFECT_CREATE
	else
		--LOG("------------ here")
		--damage.iAcid = EFFECT_REMOVE --doesn't work
		ret:AddScript("Board:SetAcid("..pB:GetString()..", false)")
	end

	---Fire
	if Board:IsFire(pB) then
		damage.iFire = EFFECT_CREATE
	else
		damage.iFire = EFFECT_REMOVE
	end

	---Shield
	if Board:IsShield(pB) then
		damage.iShield = EFFECT_CREATE
	else
		--damage.iShield = EFFECT_REMOVE --doesn't work
		ret:AddScript("Board:SetShield("..pB:GetString()..", false)")
	end

	if self.SwapSmoke then
		if Board:IsSmoke(pB) then
			damage.iSmoke = EFFECT_CREATE
		else
			damage.iSmoke = EFFECT_REMOVE
		end
	end

	--[[
	TODO:
	- crack (not literally, come on)
	]]
end

--Exclude p2 and p3
--Take points that are actually valid (no mountains, lava, water, ice, etc.)
local function GetValidTempSpawnPoint(p2, p3)
	for j = 0, 7 do
		for i = 0, 7 do
			local curr = Point(i, j)
			if curr ~= p2 and curr ~= p3 and Board:IsBlocked(curr, PATH_PROJECTILE) and Board:GetTerrain(curr) == TERRAIN_ROAD then
				return curr
			end
		end
	end
	LOG("GetValidTempSpawnPoint: couldn't find a fitting temporary space!")
	return Point(-1, -1)
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

local function EVENT_onFinalEffectEnd(mission, pawn, weaponId, p1, p2, p3)

	if type(weaponId) == 'table' then weaponId = weaponId.__Id end

	if weaponId == "truelch_RiftInducer" or
			weaponId == "truelch_RiftInducer_A" or
			weaponId == "truelch_RiftInducer_B" or
			weaponId == "truelch_RiftInducer_AB" then
		
		--Is Rift Inducer. Should we do the whole logic here or just the spawn swap?
		--Advantages: easier to do custom timings / delays
		--Inconvenients: I don't think potential kills will be credited to the Mech

		local ret = SkillEffect()

		---- TEST: MOVE UNITS TO (-1, -1) ----
		local pawn2 = Board:GetPawn(p2)
		local pawn3 = Board:GetPawn(p3)

		if pawn2 ~= nil then
			pawn2:SetSpace(Point(-1, -1))
		end

		if pawn3 ~= nil then
			pawn3:SetSpace(Point(-1, -1))
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
		local maxHealth2 = Board:GetMaxHealth(p2) --local maxHealth2 = Board:GetHealth(p2) --wups, I wrongly NOT used GetMaxHealth
		--shield, acid, smoke, fire, frozen, crack, ???
		local shield2 = Board:IsShield(p2)
		local acid2   = Board:IsAcid(p2)
		local smoke2  = Board:IsSmoke(p2)
		local fire2   = Board:IsFire(p2)
		local crack2  = Board:IsCracked(p2)

		local tile3 = Board:GetTerrain(p3)
		local currHealth3 = Board:GetHealth(p3)
		local maxHealth3 = Board:GetMaxHealth(p3) --local maxHealth3 = Board:GetHealth(p3) --same as above
		--shield, acid, smoke, fire, frozen, crack, ???
		local shield3 = Board:IsShield(p3)
		local acid3   = Board:IsAcid(p3)
		local smoke3  = Board:IsSmoke(p3)
		local fire3   = Board:IsFire(p3)
		local crack3  = Board:IsCracked(p3) --doesn't work with Damaged Ice or Damaged Mountains

		--TODO: swapping building with water will put the building in water (still is the case?)

		---- REMOVE EFFECTS (ACID, SHIELD, FIRE, SMOKE, ...) ----
		if not shield2 then
			--ret:AddScript("Board:SetShield("..p3:GetString()..", false)")
			Board:SetShield(p3, false)
		end
		if not shield3 then
			--ret:AddScript("Board:SetShield("..p2:GetString()..", false)")
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
			Board:SetSmoke(p3, false, false) --idk why there are 2 bool arguments, maybe showing the animation of appear/disappear?
		end
		if not smoke3 then
			Board:SetSmoke(p2, false, false) --idk why there are 2 bool arguments, maybe showing the animation of appear/disappear?
		end

		--Problem: removing crack from cracked frozen water will not revert it to frozen water but to regular water
		if crack2 then
			Board:SetCracked(p3, false)
		end
		if crack3 then
			Board:SetCracked(p2, false)
		end

		---- SET BUILDING HEALTH ----
		--old way to change terrain:
		--local setTerrain2 = SpaceDamage(p2, 0)
		--setTerrain2.iTerrain = tile3
		--ret:AddDamage(setTerrain2)

		if tile3 == TERRAIN_BUILDING and tile2 == TERRAIN_WATER then
			--Attempt to fix water <-> building swap
			--Result: instead of having a building on water, we get an evacuated building. yay
			Board:SetTerrain(p2, TERRAIN_ROAD)
			modApi:scheduleHook(550, function()
			end)
		end
		Board:SetTerrain(p2, tile3)
		
		--This line below also automatically cracks damaged mountains / ice
		ret:AddScript(string.format("Board:SetHealth(%s, %s, %s)", p2:GetString(), tostring(currHealth3), tostring(maxHealth3)))

		--old way to change terrain:
		--local setTerrain3 = SpaceDamage(p3, 0)
		--setTerrain3.iTerrain = tile2
		--ret:AddDamage(setTerrain3)

		if tile2 == TERRAIN_BUILDING and tile3 == TERRAIN_WATER then
			--Attempt to fix water <-> building swap
			--Result: instead of having a building on water, we get an evacuated building. yay
			Board:SetTerrain(p3, TERRAIN_ROAD)
			modApi:scheduleHook(550, function()				
			end)
		end
		Board:SetTerrain(p3, tile2)

		--This line below also automatically cracks damaged mountains / ice
		ret:AddScript(string.format("Board:SetHealth(%s, %s, %s)", p3:GetString(), tostring(currHealth2), tostring(maxHealth2)))

		--better to place it here
		Board:AddEffect(ret) 

		---- NEW: RELOCATE UNITS ----
		--no idea if the delay is needed yet, but let's do this
		modApi:scheduleHook(550, function()
		if pawn2 ~= nil then
			pawn2:SetSpace(p3)
		end

		if pawn3 ~= nil then
			pawn3:SetSpace(p2)
		end

		modApi:scheduleHook(550, function()

		---- ADD STATUS (ACID, SHIELD, FIRE, SMOKE, ...) ----
		if shield2 then
			Board:AddShield(p3)
		end
		if shield3 then
			Board:AddShield(p2)
		end

		if acid2 then
			--ret:AddScript("Board:SetAcid("..pB:GetString()..", false)")
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

		if crack2 then
			Board:SetCracked(p3, true)
		end
		if crack3 then
			Board:SetCracked(p2, true)
		end

		end)
		end)

	end
end

modapiext.events.onFinalEffectEnd:subscribe(EVENT_onFinalEffectEnd)