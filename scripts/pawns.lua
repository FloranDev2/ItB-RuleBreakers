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
	Image = "MechBottlecap",
	ImageOffset = 9,
	SkillList = { "Brute_TC_GuidedMissile" },
	SoundLocation = "/enemy/bouncer_2/",
	DefaultTeam = TEAM_PLAYER,
	ImpactMaterial = IMPACT_METAL,
	Massive = true,
	Flying = true,
	IgnoreSmoke = true,
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
	SkillList = { },
	SoundLocation = "/enemy/burrower_2/",
	DefaultTeam = TEAM_PLAYER,
	ImpactMaterial = IMPACT_METAL,
	Massive = true,
}

--[[
--I didn't added that at first, but I might need that in the end
local oldMove = Move.GetTargetArea
function Move:GetTargetArea(p, ...)
	local mover = Board:GetPawn(p)
	if mover and (mover:GetType() == "truelch_BurrowerMech") then
		local pathType
		if Board:GetTerrain(p) == TERRAIN_WATER then pathType = mover:GetPathProf() else pathType = PATH_FLYER end
		local old = extract_table(Board:GetReachable(p, mover:GetMoveSpeed(), pathType))
		local ret = PointList()

		for _, v in ipairs(old) do
			local terrain = Board:GetTerrain(v)

			if terrain ~= TERRAIN_HOLE and terrain ~= TERRAIN_WATER then
				ret:push_back(v)
			end
		end

		return ret
	end

	return oldMove(self, p, ...)
end

--Stolen that from Metalocif!
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