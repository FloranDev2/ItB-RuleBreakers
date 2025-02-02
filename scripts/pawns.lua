local resourcePath = mod_loader.mods[modApi.currentMod].resourcePath
local scriptPath = mod_loader.mods[modApi.currentMod].scriptPath
local mechPath = resourcePath .."img/mechs/"
local mod = modApi:getCurrentMod()
--local mechDiversYellow = modApi:getPaletteImageOffset("truelch_MechDiversYellow")

--to do for both sawblade and upgraded saw blade:
local trait = require(scriptPath.."/libs/trait") --unnecessary?
trait:add{
    pawnType = "truelch_DislocationMech",
    icon = "img/combat/icons/icon_protecc.png",
    icon_offset = Point(0, 0),
    desc_title = "Grid Protector",
    desc_text = "Can teleport to Buildings in move range."
}


----------------
--- Saw Mech ---
----------------

truelch_SawbladeMech = Pawn:new {
	Name = "Sawblade Mech",
	Class = "Brute",
	Health = 3,
	MoveSpeed = 3,
	Image = "MechPierce",
	--ImageOffset = palette,
	ImageOffset = 9,
	SkillList = { "truelch_SawbladeLauncher" },
	SoundLocation = "/mech/brute/pierce_mech/",
	DefaultTeam = TEAM_PLAYER,
	ImpactMaterial = IMPACT_METAL,
	Massive = true,
}


-----------------
--- Grid Mech ---
-----------------

truelch_GridMech = Pawn:new {
	Name = "Grid Mech",
	Class = "Science",
	Health = 3,
	MoveSpeed = 4,
	Image = "MechTritube",
	ImageOffset = 9,
	SkillList = { "truelch_GridDischarge" },
	SoundLocation = "/enemy/bouncer_2/",
	DefaultTeam = TEAM_PLAYER,
	ImpactMaterial = IMPACT_METAL,
	Massive = true,
	Flying = true,
	IgnoreSmoke = true,
	WebImmune = true,
	Pushable = false, --maybe?
}


------------------------
--- Dislocation Mech ---
------------------------

truelch_DislocationMech = Pawn:new {
	Name = "Dislocation Mech",
	Class = "Ranged",
	Health = 2,
	MoveSpeed = 3,
	Image = "MechArt",
	ImageOffset = 9,
	SkillList = { "Ranged_Arachnoid", "Support_Refrigerate" },
	SoundLocation = "/enemy/burrower_2/",
	DefaultTeam = TEAM_PLAYER,
	ImpactMaterial = IMPACT_METAL,
	Massive = true,
	--Corpse = false, --test?
}

--I didn't added that at first, but I might need that in the end
local oldMove = Move.GetTargetArea
function Move:GetTargetArea(p, ...)
	local mover = Board:GetPawn(p)
	if mover and mover:GetType() == "truelch_GridMech" then
		LOG("------- Grid Mech special move")

		local ret = PointList()

		local moveSpeed = mover:GetMoveSpeed()

		LOG("------- moveSpeed: "..tostring(moveSpeed))

		--[[
		local iMin = math.max(0, p.x - moveSpeed)
		local iMax = math.min(7, p.x + moveSpeed)

		local jMin = math.max(0, p.y - moveSpeed)
		local jMax = math.min(7, p.y + moveSpeed)

		--LOGF("iMin: %s, iMax: %s, jMin: %s, jMax: %s", tostring(iMin), tostring(iMax), tostring(jMin), tostring(jMax))

		--lazy approach
		for j = jMin, jMax do
			for i = iMin, iMax do
				local curr = p + Point(i, j)
				--LOG("curr: "..curr:GetString())
				if p:Manhattan(curr) <= moveSpeed and Board:IsBuilding(curr) then
					LOG("------- added: "..curr:GetString())
					ret:push_back(curr)
				end
			end
		end
		]]

		--Test
		for j = 0, 7 do
			for i = 0, 7 do
				local curr = Point(i, j)
				if Board:IsBuilding(curr) then
					ret:push_back(curr)
				end
			end
		end

		return ret
	end

	return oldMove(self, p, ...)
end


local oldMove = Move.GetSkillEffect
function Move:GetSkillEffect(p1, p2, ...)
	local mover = Board:GetPawn(p1)
	if mover and mover:GetType() == "truelch_GridMech" then
		local ret = SkillEffect()
		ret:AddTeleport(p1, p2, NO_DELAY)
		ret:AddSound("/weapons/force_swap")
		return ret
	end

	return oldMove(self, p1, p2, ...)
end