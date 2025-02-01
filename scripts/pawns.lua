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

		local iMin = math.max(0, p.x)
		local iMax = math.min(7, p.x)

		local jMin = math.max(0, p.y)
		local jMax = math.min(7, p.y)

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

		return ret
	end

	return oldMove(self, p, ...)
end

--[[
local oldMove = Move.GetSkillEffect
function Move:GetSkillEffect(p1, p2, ...)
	local mover = Board:GetPawn(p1)
	if mover and (mover:GetType() == "truelch_BurrowerMech") then
		local ret = SkillEffect()
		local pawnId = mover:GetId()

		-- just preview move.
		-- ret:AddScript(string.format("Board:GetPawn(%s):SetSpace(Point(-1, -1))", pawnId))
		if not Board:IsTerrain(p1, TERRAIN_WATER) and not Board:IsTerrain(p2, TERRAIN_WATER) and p1:Manhattan(p2) > 1 then
		--it's annoying to go through the whole burrowing animation for one tile so we force a normal Move
		--could probably check whether it's possible to move to p2 without burrowing but this helps a little
			ret:AddBurrow(Board:GetPath(p1, p2, PATH_FLYER), NO_DELAY)
			ret:AddSound("/enemy/shared/crawl_out")
			ret:AddDelay(0.7)	--burrowing anim duration
			local path = extract_table(Board:GetPath(p1, p2, PATH_FLYER))
			local dist = #path - 1
			for i = 1, #path do
				local p = path[i]
				ret:AddBounce(p, -2)
				ret:AddDelay(.32 / dist)
			end
		else
			ret:AddMove(Board:GetPath(p1, p2, mover:GetPathProf()), FULL_DELAY)
		end


		return ret
	end

	return oldMove(self, p1, p2, ...)
end
]]