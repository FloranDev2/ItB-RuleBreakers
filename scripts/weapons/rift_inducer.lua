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

local riftAreaVersion --1: lines, 2: squares, 3: manhattan
modApi.events.onModLoaded:subscribe(function(id)
	if id ~= mod.id then return end
	local options = mod_loader.currentModContent[id].options
	riftAreaVersion = options["option_rift_area"].value
	--LOG("riftAreaVersion: "..tostring(riftAreaVersion))
end)

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
			LOG("rift pawn exception: "..pawn:GetType())
			return true
		end
	end

	return false
end

--[[
Also exclude items? Or just pods?
]]
local function isLocOkForRift(point)
	local item = Board:GetItem(point) --it's "" and not nil but let's do both
	return true and
		Board:IsValid(point) and
		(pawn == nil or not isRiftExc(pawn)) and
		(Board:GetUniqueBuilding(point) == nil or Board:GetUniqueBuilding(point) == "") and
		(item == nil or item == "") and
		not Board:IsPod(point)
end

truelch_RiftInducer = Skill:new{
	--Infos
	Name = "Rift Inducer",
	Description = "Shoot a projectile opening a spatial rift at the target tile.\nCannot target special buildings, dams and time pods.",
	Class = "Ranged",
	Icon = "weapons/truelch_rift_inducer.png",

	--Shop
	Rarity = 1,
	PowerCost = 0,
	
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
	points = {}

	--riftAreaVersion --1: lines, 2: squares, 3: manhattan
	--LOG("riftAreaVersion: "..tostring(riftAreaVersion))

	--[[
	for j = 0, 7 do
		for i = 0, 7 do
			local curr = Point(i, j)
			if curr ~= p2 then
				points[#points + 1] = curr
			end
		end
	end
	]]
	
	--[[
	if riftAreaVersion == 1 then
		--Lines
		for dir = DIR_START, DIR_END do
			for i = 1, self.SecondTargetRange do
				local curr = p2 + DIR_VECTORS[dir] * i
				local pawn = Board:GetPawn(curr)

				if isLocOkForRift(curr) then
					--ret:push_back(curr)
					points[#points + 1] = curr
				end
			end
		end
	elseif riftAreaVersion == 2 then
		--Square
		for j = -self.Range, self.Range do
			for i = -self.Range, self.Range do
				local curr = Point(i, j)
				if i ~= 0 or j ~= 0 then
					points[#points + 1] = curr
				end
			end
		end
	elseif riftAreaVersion == 3 then
		--Distance (lazy way)		
		for j = 0, 7 do
			for i = 0, 7 do
				local curr = Point(i, j)
				local dist = p2:Manhattan(curr)
				if dist <= self.Range and dist > 0 then
					points[#points + 1] = curr
				end 
			end
		end
	else
		LOG("truelch_RiftInducer:GetSecAreaPoints -> unexpected riftAreaVersion: "..tostring(riftAreaVersion))
	end
	]]

	--Return
	return points
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
	--Yes, we gonna swap even tiles occupied by Stable pawns!
	--[[
	elseif Board:GetPawn(p2):IsGuarding() then
		damage.sImageMark = "combat/icons/icon_guard_glow.png"
	]]
	else
		damage.sImageMark = "advanced/combat/icons/icon_teleport_glow.png"
	end

	--damage.sImageMark = "combat/icons/icon_swap_impossible.png"

	ret:AddArtillery(damage, self.UpShot)

	return ret
end

function truelch_RiftInducer:GetSecondTargetArea(p1, p2)
	local ret = PointList()
	
	--[[
	for dir = DIR_START, DIR_END do
		for i = 1, self.SecondTargetRange do
			local curr = p2 + DIR_VECTORS[dir] * i
			local pawn = Board:GetPawn(curr)

			if isLocOkForRift(curr) then
				ret:push_back(curr)
			end
		end
	end
	]]

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

	--return Point(-1, -1) --test

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

	--SWAP TILES!!!
	local tile2 = Board:GetTerrain(p2)
	local currHealth2 = Board:GetHealth(p2)
	local maxHealth2 = Board:GetHealth(p2)

	local tile3 = Board:GetTerrain(p3)
	local currHealth3 = Board:GetHealth(p3)
	local maxHealth3 = Board:GetHealth(p3)

	---- P2 ----
	local riftAnim2 = SpaceDamage(p2, 0)
	--riftAnim2.sAnimation = "RiftUnit"	
	riftAnim2.sSound = "/weapons/swap"
	--Remove statuses from other tile
	--Add statuses from other tile
	self:ComputeTile(ret, riftAnim2, p2, p3)
	ret:AddDamage(riftAnim2)

	---- P3 ----
	local riftAnim3 = SpaceDamage(p3, 0)
	--riftAnim3.sAnimation = "rift_unit"
	--riftAnim2.sSound = "/weapons/swap" --no need to play the sound twice
	--Remove statuses from other tile	
	--Add statuses from other tile
	self:ComputeTile(ret, riftAnim3, p3, p2)
	ret:AddDamage(riftAnim3)

	ret:AddScript(string.format("Board:SetTerrain(%s, %s)",    p2:GetString(), tostring(tile3)))
	ret:AddScript(string.format("Board:SetHealth(%s, %s, %s)", p2:GetString(), tostring(currHealth3), tostring(maxHealth3)))

	ret:AddScript(string.format("Board:SetTerrain(%s, %s)",    p3:GetString(), tostring(tile2)))
	ret:AddScript(string.format("Board:SetHealth(%s, %s, %s)", p3:GetString(), tostring(currHealth2), tostring(maxHealth2)))

	--SWAP UNITS
	local delay = Board:IsPawnSpace(p3) and 0 or FULL_DELAY
	ret:AddTeleport(p2, p3, delay)
	
	if delay ~= FULL_DELAY then
		ret:AddTeleport(p3, p2, FULL_DELAY)
	end

	--SWAP SPAWNS (-> moved to the skill ended because swapping two spawns is buggy)
	--or I could just do nothing when we swap 2 spawns

	--[[
	local m = GetCurrentMission()

	local spawn2 = m:GetSpawnPointData(p2)
	local spawn3 = m:GetSpawnPointData(p3)

	if spawn2 ~= nil and spawn3 ~= nil then
		--Swap. But idk if it'll work if I do this:
		--Or maybe I should move temporarily one of them to a tile free of spawn and then move it back
		local tmpPos = GetValidTempSpawnPoint(p2, p3)
		ret:AddScript(string.format("GetCurrentMission():MoveSpawnPoint(%s, %s)", p2:GetString(), tmpPos:GetString()))
		ret:AddDelay(0.5)
		ret:AddScript(string.format("GetCurrentMission():MoveSpawnPoint(%s, %s)", p3:GetString(), p2:GetString()))
		ret:AddDelay(0.5)
		ret:AddScript(string.format("GetCurrentMission():MoveSpawnPoint(%s, %s)", tmpPos:GetString(), p3:GetString()))

	elseif spawn2 ~= nil then
		--Move spawn2 to p3
		ret:AddScript(string.format("GetCurrentMission():MoveSpawnPoint(%s, %s)", p2:GetString(), p3:GetString()))

	elseif spawn3 ~= nil then
		--Move spawn3 to p2
		ret:AddScript(string.format("GetCurrentMission():MoveSpawnPoint(%s, %s)", p3:GetString(), p2:GetString()))

	else
		--No spawn on both tiles -> do nothing

	end
	]]	
	
	return ret
end

--[[
LOG(save_table(GetCurrentMission().QueuedSpawns))

[1] = {
	["type"] = "Firefly1", 
	["location"] = Point( 5, 3 ), 
	["turns"] = 1, 
	["id"] = 103 
},
[2] = {
	["type"] = "Moth1", 
	["location"] = Point( 7, 4 ), 
	["turns"] = 1, 
	["id"] = 104 
}
]]
local function EVENT_onFinalEffectEnd(mission, pawn, weaponId, p1, p2, p3)
    if not functions:isMission() then return end

	if type(weaponId) == 'table' then weaponId = weaponId.__Id end

	if weaponId == "truelch_RiftInducer" or
			weaponId == "truelch_RiftInducer_A" or
			weaponId == "truelch_RiftInducer_B" or
			weaponId == "truelch_RiftInducer_AB" then
		
		local spawn2 = mission:GetSpawnPointData(p2)
		local spawn3 = mission:GetSpawnPointData(p3)

		if spawn2 ~= nil and spawn3 ~= nil then
			--I can just... do nothing
			--The only thing that'd make it visible that I didn't swap emerge points is the pilot that reveals emerging vek lol
			--Or I could change the spawn data from both in a single frame
			--LOG("---------------- [A] Swap")

			--V0: do nothing lol

			--V1: moving p2 to a temporary point -> move p3 to p2 -> move temp (p2) to p3
			--Note: trying to swap two spawns in the same frame will result on a spawn overriding another
			--I've also tried moving temporarily to (-1, -1) but it just put back in a very random position for some reason
			--[[
			local tmpPos = GetValidTempSpawnPoint(p2, p3)
			mission:MoveSpawnPoint(p2, tmpPos)
			modApi:scheduleHook(550, function()
				mission:MoveSpawnPoint(p3, p2)
				modApi:scheduleHook(550, function()
					mission:MoveSpawnPoint(tmpPos, p3)
				end)
			end)
			]]

			--V2: inverting data (or pawns if swapping data doesn't work)
			--Okay, doing it at the same frame will make p2 emerge!
			--V2a
			--[[
			mission:ModifySpawnPoint(p2, spawn3)
			modApi:scheduleHook(550, function()
				mission:ModifySpawnPoint(p3, spawn2)
			end)
			]]

			--V2b
			--Maybe I should have modified the spawn data location and injected afterwards
			--Making it in the same frame emerge both (okay, even with the delay it emerges both)
			--[[
			spawn2.location = p3
			spawn3.location = p2
			mission:ModifySpawnPoint(p2, spawn3)
			modApi:scheduleHook(550, function()
				mission:ModifySpawnPoint(p3, spawn2)
			end)
			]]

			--V3: just change pawn type
			--This also emerges both... *sigh*
			--[[
			mission:ChangeSpawnPointPawnType(p2, spawn3.type)
				modApi:scheduleHook(550, function()
			mission:ChangeSpawnPointPawnType(p3, spawn2.type)
			end)
			]]

		elseif spawn2 ~= nil then
			--Move spawn2 to p3
			--LOG("---------------- [B] p2 -> p3")
			mission:MoveSpawnPoint(p2, p3)

		elseif spawn3 ~= nil then
			--Move spawn3 to p2
			--LOG("---------------- [C] p3 -> p2")
			mission:MoveSpawnPoint(p3, p2)

		else
			--No spawn on both tiles -> do nothing
			--LOG("---------------- [D] no spawns")

		end
	end
end

modapiext.events.onFinalEffectEnd:subscribe(EVENT_onFinalEffectEnd)