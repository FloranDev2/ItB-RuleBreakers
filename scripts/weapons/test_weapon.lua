local terrainVal = 0

truelch_test_weapon = Skill:new{
	--Infos
	Name = "Test Weapon",
	Description = "Test.",
	Class = "Science",
	Icon = "weapons/enemy_rocker1.png",
	--Shop
	Rarity = 1,
	PowerCost = 0,
}

--8, 10, 13??
--8 gives a road but tooltip doesn't display any information
--10 doesn't change the terrain
--13 works just like 8
LOG("TERRAIN_ROAD: "    ..tostring(TERRAIN_ROAD)) --0
LOG("TERRAIN_BUILDING: "..tostring(TERRAIN_BUILDING)) --1
LOG("TERRAIN_RUBBLE: "  ..tostring(TERRAIN_RUBBLE)) --2
LOG("TERRAIN_WATER: "   ..tostring(TERRAIN_WATER)) --3
LOG("TERRAIN_MOUNTAIN: "..tostring(TERRAIN_MOUNTAIN)) --4
LOG("TERRAIN_ICE: "     ..tostring(TERRAIN_ICE)) --5
LOG("TERRAIN_FOREST: "  ..tostring(TERRAIN_FOREST)) --6
LOG("TERRAIN_SAND: "    ..tostring(TERRAIN_SAND)) --7
LOG("TERRAIN_HOLE: "    ..tostring(TERRAIN_HOLE)) --9
LOG("TERRAIN_FIRE: "    ..tostring(TERRAIN_FIRE)) --11
LOG("TERRAIN_ACID: "    ..tostring(TERRAIN_ACID)) --12
LOG("TERRAIN_LAVA: "    ..tostring(TERRAIN_LAVA)) --14


function truelch_test_weapon:GetTargetArea(point)
	local ret = PointList()
	for j = 0, 7 do
		for i = 0, 7 do
			ret:push_back(Point(i, j))
		end
	end	
	return ret
end

function truelch_test_weapon:GetSkillEffect(p1, p2)
	local ret = SkillEffect()

	--local damage = SpaceDamage(p2, 0)
	--damage.iAcid = EFFECT_CREATE
	--damage.iShield = EFFECT_CREATE
	--damage.iFire = EFFECT_CREATE
	--damage.iSmoke = EFFECT_CREATE
	--damage.iTerrain = 13
	--ret:AddDamage(damage)	

	--[[
	if not Board:IsFire(p2) then		
		local damage = SpaceDamage(p2, 0)
		damage.iFire = EFFECT_CREATE
		ret:AddDamage(damage)
		
		ret:AddScript(string.format("Board:SetFire(%s, true)", p2:GetString()))
	else
		ret:AddScript(string.format("Board:SetFire(%s, false)", p2:GetString()))
	end
	]]

	--[[
	if not Board:IsSmoke(p2) then
		ret:AddScript(string.format("Board:SetSmoke(%s, true, false)", p2:GetString()))
	else
		ret:AddScript(string.format("Board:SetSmoke(%s, false, true)", p2:GetString()))
	end
	]]

	--Board:Crack() --not sure about the arguments
	--Board:SetCracked(pawn:GetSpace(), false)


	if not Board:IsCracked(p2) then
		LOG("NOT CRACKED")
		ret:AddScript(string.format("Board:SetCracked(%s, true)", p2:GetString()))
	else
		LOG("IS CRACKED")
		--IS cracked
		if Board:GetTerrain(p2) == TERRAIN_ICE then
			LOG("TERRAIN_ICE")
		elseif Board:GetTerrain(p2) == TERRAIN_WATER then
			LOG("TERRAIN_WATER")
		else
			LOG("ELSE: WE CAN ACTUALLY SET CRACKED TO FALSE")
			ret:AddScript(string.format("Board:SetCracked(%s, false)", p2:GetString()))
		end		
	end

	return ret
end

local EVENT_onSkillEnd = function(mission, pawn, weaponId, p1, p2)
	LOG(string.format("%s has finished using %s at %s!", pawn:GetMechName(), weaponId, p2:GetString()))

	if type(weaponId) == 'table' then weaponId = weaponId.__Id end

	if weaponId == "truelch_debug_weapon" then
		LOG("tile: "..tostring(Board:GetTerrain(p2)..", isCrackable: "..tostring(Board:IsCrackable(p2))..", isCracked: "..tostring(Board:IsCracked(p2))))
		local currHealth2 = Board:GetHealth(p2)
		local maxHealth2 = Board:GetMaxHealth(p2)
		LOG("currHealth2: "..tostring(currHealth2)..", maxHealth2: "..tostring(maxHealth2))
	end

	--Test add building
	--ret:AddScript(string.format("Board:SetTerrain(%s, TERRAIN_BUILDING)", p2:GetString()))
	--ret:AddScript(string.format("Board:SetHealth(%s, 1, 2", p2:GetString()))

	--it seems that setting terrain from water and mountain creates evacuated buildings with 2 hp
	--otherwise, it's 4-hp regular buildings
	--if Board:GetTerrain(p2) == TERRAIN_MOUNTAIN or Board:GetTerrain(p2) == TERRAIN_WATER then
		--LOG("Here")
		--ret:AddScript(string.format("Board:SetTerrain(%s, TERRAIN_ROAD)", p2:GetString()))
	--else
		--ret:AddScript(string.format("Board:SetTerrain(%s, TERRAIN_BUILDING)", p2:GetString()))
	--end

	--https://github.com/itb-community/ITB-ModLoader/wiki/%5BVanilla%5D-SpaceDamage#iterrain
	--In addition, they list all terrains constants (like TERRAIN_ROAD)
	--dmg.iTerrain = TERRAIN_ROAD --so uh this exists

	--LOG("terrainVal: "..tostring(terrainVal))

	--modApi:scheduleHook(550, function()
	--end)
end


modapiext.events.onSkillEnd:subscribe(EVENT_onSkillEnd)


--[[
1: 49
2: 50
3: 51
...
]]

--[[
local handler = function(scancode)
    LOGF("Key with scancode %s is being released and processed", scancode)
    LOG("-------- type: "..type(scancode))

    if scancode     == 1073741906 then --UP
        LOG(" -> Up!")
    elseif scancode == 1073741905 then --DOWN
        LOG(" -> Down!")
    elseif scancode == 1073741904 then --LEFT
        LOG(" -> Left!")
    elseif scancode == 1073741903 then --RIGHT
        LOG(" -> Right!")
    end
end

modApi.events.onKeyReleased:subscribe(handler)
]]