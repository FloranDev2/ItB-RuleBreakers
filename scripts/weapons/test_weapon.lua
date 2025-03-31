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
--[[
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
]]

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

	if not Board:IsCracked(p2) then
		local damage = SpaceDamage(p2, 0)
		damage.iCrack = EFFECT_CREATE
		ret:AddDamage(damage)
	else
		LOG("Here")
		--local damage = SpaceDamage(p2, 0)
		--damage.iCrack = EFFECT_REMOVE
		--ret:AddDamage(damage)
		ret:AddScript(string.format("Board:SetCracked(%s, false)", p2:GetString()))
	end

	return ret
end

local EVENT_onSkillEnd = function(mission, pawn, weaponId, p1, p2)
	--LOG(string.format("%s has finished using %s at %s!", pawn:GetMechName(), weaponId, p2:GetString()))

	if type(weaponId) == 'table' then weaponId = weaponId.__Id end

	if weaponId ~= "truelch_test_weapon" then return end

	LOG("HERE")

	local effect = SkillEffect()
	local damage = SpaceDamage(p2, 0)
	damage.iTerrain = TERRAIN_ROAD
	effect:AddDamage(damage)
	effect:AddDelay(0.1)
	local damage = SpaceDamage(p2, 0)
	damage.iTerrain = TERRAIN_BUILDING
	effect:AddDamage(damage)
	Board:AddEffect(effect)
	
	modApi:scheduleHook(550, function()
		local ret = SkillEffect()
		ret:AddScript(string.format("Board:SetHealth(%s, 2, 2)", p2:GetString()))
		Board:AddEffect(ret)
	end)
end


--modapiext.events.onSkillEnd:subscribe(EVENT_onSkillEnd)


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