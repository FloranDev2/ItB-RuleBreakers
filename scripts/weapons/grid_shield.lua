truelch_GridShield = Skill:new{
	--Infos
	Name = "Grid Shield",
	Description = "Teleport to a city within move range.\nShield the unit and the building.",
	Class = "Science",
	Icon = "weapons/truelch_grid_shield.png",

	--Shop
	Rarity = 1,
	PowerCost = 0,
	
	Upgrades = 2,
	UpgradeCost = { 1, 1 },

	--Gameplay
	AutoShield = false, --only for tip image
	PushAdjacent = false,

	--Tip image
	TipImage = {
		Unit       = Point(2, 3),
		Building   = Point(2, 2),
		Building2  = Point(2, 3),
		Enemy1     = Point(2, 1),
		Queued1    = Point(2, 2),
		Target     = Point(2, 2),
		CustomPawn = "truelch_GridMech"
	}
}

modApi:addWeaponDrop("truelch_GridShield")

Weapon_Texts.truelch_GridShield_Upgrade1 = "Auto-shield"
Weapon_Texts.truelch_GridShield_Upgrade2 = "Explosive Shield"

truelch_GridShield_A = truelch_GridShield:new{
	UpgradeDescription = "Automatically gain a shield at round start.",
	AutoShield = true,
}

truelch_GridShield_B = truelch_GridShield:new{
	UpgradeDescription = "Deploying the shield pushes adjacent unit",
	PushAdjacent = true,
}

truelch_GridShield_AB = truelch_GridShield:new{
	AutoShield = true,
	PushAdjacent = true,
}

function truelch_GridShield:GetTargetArea(point)
	local ret = PointList()

	local moveSpeed = Pawn:GetMoveSpeed() --webbed = move 0
	--LOG("moveSpeed: "..tostring(moveSpeed))

	--can target self?

	--yes, I'm lazy
	for j = 0, 7 do
		for i = 0, 7 do
			local curr = Point(i, j)
			if point:Manhattan(curr) <= moveSpeed and Board:IsBuilding(curr) then
				ret:push_back(curr)
			end
		end
	end
	
	return ret
end

function truelch_GridShield:GetSkillEffect(p1, p2)
	local ret = SkillEffect()

	if Board:IsTipImage() and self.AutoShield then
		Board:AddAlert(p1, "Auto-Shield")
		local autoShield = SpaceDamage(p1, 0)
		autoShield.iShield = 1
		ret:AddDamage(autoShield)
	end

	ret:AddTeleport(p1, p2, FULL_DELAY)

	local shield = SpaceDamage(p2, 0)
	shield.iShield = 1
	ret:AddDamage(shield)

	if self.PushAdjacent then
		for dir = DIR_START, DIR_END do
			local curr = p2 + DIR_VECTORS[dir]
			local push = SpaceDamage(curr, 0)
			push.sAnimation = "airpush_"..dir
			push.iPush = dir
			ret:AddDamage(push)
		end
	end

	return ret
end

local function EVENT_onNextTurn(mission)
	if Game:GetTeamTurn() == TEAM_PLAYER then
		for i = 0, 2 do
			local mech = Board:GetPawn(i)
			--only if the mech is on a building?
			if mech ~= nil and (mech:IsWeaponPowered("truelch_GridShield_A") or mech:IsWeaponPowered("truelch_GridShield_AB")) then
				mech:SetShield(true)
				Board:AddAlert(mech:GetSpace(), "Auto-Shield")
			end
		end
	end
end

modApi.events.onNextTurn:subscribe(EVENT_onNextTurn)