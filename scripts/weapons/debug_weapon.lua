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

function truelch_debug_weapon:GetSkillEffect(p1, p2)
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


function truelch_debug_weapon:GetSkillEffect_OLD(p1, p2)
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