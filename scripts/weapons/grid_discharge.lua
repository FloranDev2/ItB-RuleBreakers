truelch_GridDischarge = Skill:new{
	--Infos
	Name = "Grid Discharge",
	Description = "Deal damage equal to current grid power to an adjacent target.",
	Class = "Science",
	Icon = "weapons/truelch_grid_discharge.png",

	--Shop
	Rarity = 1,
	PowerCost = 0,
	
	Upgrades = 2,
	UpgradeCost = { 1, 1 },

	--Gameplay
	Limited = 1,

	--Art
	Anim = "",

	--Tip image
	TipImage = {
		Unit       = Point(2, 2),
		Building   = Point(2, 2),
		Enemy      = Point(2, 1),
		Target     = Point(2, 1),
		CustomPawn = "truelch_GridMech"
	}
}

modApi:addWeaponDrop("truelch_GridDischarge")

Weapon_Texts.truelch_GridDischarge_Upgrade1 = "+1 Use"
Weapon_Texts.truelch_GridDischarge_Upgrade2 = "+1 Use"

truelch_GridDischarge_A = truelch_GridDischarge:new{
	UpgradeDescription = "Increases uses per battle by one.",
	Limited = 2,
}

truelch_GridDischarge_B = truelch_GridDischarge:new{
	UpgradeDescription = "Increases uses per battle by one.",
	Limited = 2,
}

truelch_GridDischarge_AB = truelch_GridDischarge:new{
	Limited = 3,
}

function truelch_GridDischarge:GetTargetArea(point)
	local ret = PointList()

	for dir = DIR_START, DIR_END do
		local curr = point + DIR_VECTORS[dir]
		ret:push_back(curr)
	end
	
	return ret
end

function truelch_GridDischarge:GetSkillEffect(p1, p2)
	local ret = SkillEffect()

	local dmg = 5 --initial grid is 5 so preview from hangar is more accurate
	if Game ~= nil then
		dmg = Game:GetPower():GetValue()
	end

	local damage = SpaceDamage(p2, dmg)
	damage.sAnimation = "LightningBolt_Animated"
	ret:AddMelee(p1, damage)

	return ret
end