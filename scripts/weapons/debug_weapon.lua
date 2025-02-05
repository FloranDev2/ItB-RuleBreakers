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

function truelch_debug_weapon:GetSkillEffect(p1, p2)
	local ret = SkillEffect()

	--LOGF("At: "..)
	local building = Board:GetUniqueBuilding(p2)
	if building ~= nil and building ~= "" then
		Board:AddAlert(p2, tostring(building))
	end

	return ret
end