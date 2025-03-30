truelch_debug_weapon = Skill:new{
	--Infos
	Name = "Debug Weapon",
	Description = "Debug.",
	Class = "Science",
	Icon = "weapons/enemy_rocker1.png",

	--Shop
	Rarity = 1,
	PowerCost = 0,

	--Tip image
}

function truelch_debug_weapon:GetTargetArea(point)
	local ret = PointList()

	for j = 0, 7 do
		for i = 0, 7 do
			local curr = Point(i, j)
			ret:push_back(curr)
		end
	end
	
	return ret
end

local function debugLiveEnv(msg)
	LOG(msg)
	local mission = GetCurrentMission()

	for index, point in ipairs(mission.LiveEnvironment.Planned) do
		LOG("-------------- ENV point: "..point:GetString())
		--[[
		for i = 0, 2 do
			local mech = Board:GetPawn(i)
			if mech ~= nil and mech:IsMech() and Board:IsBuilding(mech:GetSpace()) and
				mech:GetSpace() == point then
				LOG("-------------- mech on a building is targeted by tentacle!")
				LOG("-------------- index: "..tostring(index))
				table.remove(mission.LiveEnvironment.Planned, index)
				index = index - 1 --necessary?
			end
		end
		]]
	end

end

--function Mission:RemoveSpawnPoint(point)
--function Mission:SpawnPawn(location, pawnType)
--Mission:SpawnPawnInternal(location, pawn)

--https://github.com/search?q=repo%3Aitb-community%2FITB-ModLoader%20QueuedSpawns&type=code
--https://github.com/itb-community/ITB-ModLoader/blob/675bd7d48d10b0f9230210937560ee7e551b5d18/scripts/mod_loader/altered/spawn_point.lua#L50
--https://github.com/itb-community/ITB-ModLoader/blob/675bd7d48d10b0f9230210937560ee7e551b5d18/scripts/mod_loader/altered/missions.lua#L18
function truelch_debug_weapon:GetSkillEffect(p1, p2)
	local ret = SkillEffect()

	--[[
	--SWAP SPAWNS
	--LOG("-------------- SWAP SPAWNS:")
	for _, spawn in ipairs(GetCurrentMission().QueuedSpawns) do
		--LOG("-------------- spawn: "..save_table(spawn))
		if spawn.location == p2 then
			--LOG("--------------> spawn.location == p2")
			--ret:AddScript("spawn.location = "..p3:GetString()) --attempt to index global 'spawn' (a nil value)
		elseif spawn.location == p3 then
			--LOG("--------------> spawn.location == p3")
			--ret:AddScript("spawn.location = "..p2:GetString()) --attempt to index global 'spawn' (a nil value)
		end
	end
	]]

	--ret:AddScript(string.format([[Mission:RemoveSpawnPoint(%s)]], p2:GetString()))
	--ret:AddScript(string.format([[GetCurrentMission():RemoveSpawnPoint(%s)]], p2:GetString()))
	--ret:AddScript(string.format("GetCurrentMission():RemoveSpawnPoint(%s)", p2:GetString()))

	local tmp = SpaceDamage(p2, 0)
	ret:AddDamage(tmp)

	return ret
end



function truelch_debug_weapon:GetSkillEffect_Env(p1, p2)
	local ret = SkillEffect()

	local proteccAnim = SpaceDamage(p2, 0)
    proteccAnim.sAnimation = "truelch_grid_protecc"
    ret:AddDamage(proteccAnim)

	--[[
	local mission = GetCurrentMission()
	debugLiveEnv("=== Before:")
	if mission.ID == "Mission_Final_Cave" and GetCurrentMission().LiveEnvironment.Planned ~= nil then
		mission.LiveEnvironment.Planned = { p2 }
	end
	debugLiveEnv("=== After:")
	]]

	return ret
end


function truelch_debug_weapon:GetSkillEffect_Swap(p1, p2)
	local ret = SkillEffect()

	--[[
	local building = Board:GetUniqueBuilding(p2)
	if building ~= nil and building ~= "" then
		Board:AddAlert(p2, tostring(building))
	end
	]]

	if Board:IsAcid(p2) then
	--if Board:IsFire(p2) then
	--if Board:IsSmoke(p2) then
	--if Board:IsShield(p2) then
		local damage = SpaceDamage(p2, 0)
		--damage.iAcid = EFFECT_REMOVE --doesn't work
		damage.iAcid = -2
		--ret:AddScript("Board:SetAcid("..p2:GetString()..", false)")

		--damage.iFire = EFFECT_REMOVE --works
		--damage.iSmoke = EFFECT_REMOVE --works

		--damage.IsShield = EFFECT_REMOVE --doesn't work
		--Board:SetShield(false)
		--ret:AddScript("Board:SetShield("..p2:GetString()..", false)")

		ret:AddDamage(damage)
		LOG("------------ EFFECT_REMOVE")
	else
		local damage = SpaceDamage(p2, 0)
		damage.iAcid = EFFECT_CREATE
		--damage.iFire = EFFECT_CREATE
		--damage.iSmoke = EFFECT_CREATE

		--damage.iShield = EFFECT_CREATE
		--damage:SetShield(p2, true) --unnecessary

		ret:AddDamage(damage)
		--LOG("------------ EFFECT_CREATE")
	end

	return ret
end