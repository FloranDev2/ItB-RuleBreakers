local resourcePath = mod_loader.mods[modApi.currentMod].resourcePath
local scriptPath = mod_loader.mods[modApi.currentMod].scriptPath
local mechPath = resourcePath .."img/mechs/"
local mod = modApi:getCurrentMod()
local palette = modApi:getPaletteImageOffset("truelch_RuleBreakersMagenta")

--to do for both sawblade and upgraded saw blade:
local trait = require(scriptPath.."/libs/trait") --unnecessary?
trait:add{
    pawnType = "truelch_GridMech",
    icon = "img/combat/icons/icon_grid_mech_trait.png",
    icon_offset = Point(0, 0),
    desc_title = "Grid Protector",
    desc_text = "Instead of moving, teleports to a building in move range. While the Grid Mech is alive, the building is immune to damage."
}


----------------
--- Saw Mech ---
----------------

truelch_SawbladeMech = Pawn:new {
	Name = "Sawblade Mech",
	Class = "Brute",
	Health = 3,
	MoveSpeed = 15, --3
	Image = "MechPierce",
	ImageOffset = palette,
	--ImageOffset = 9,
	SkillList = { "truelch_SawbladeLauncher", "Brute_Tankmech" },
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
	ImageOffset = palette,
	--ImageOffset = 9,
	SkillList = { "truelch_GridShield", "truelch_GridDischarge" },
	SoundLocation = "/enemy/bouncer_2/",
	DefaultTeam = TEAM_PLAYER,
	ImpactMaterial = IMPACT_METAL,
	Massive = true,
	Flying = true, --not really necessary in the end?
	IgnoreSmoke = true,
	WebImmune = true, --I think you need to do it by script
	Pushable = false, --maybe?
	--Corpse = false, --test?
}

local function computeThornDamage(p1, se)
	if se == nil or se.effect == nil then return end

	for i = 1, se.effect:size() do
		local spaceDamage = se.effect:index(i)
		local loc = spaceDamage.loc
		local dist = p1:Manhattan(loc)
		if dist == 1 then
			if isSawbladePos(loc) then
				local thornDamage = SpaceDamage(p1, 1)
				se:AddDamage(thornDamage)
			elseif isReinforcedSawbladePos(loc) then
				local thornDamage = SpaceDamage(p1, 2)
				--TODO: animation
				se:AddDamage(thornDamage)
			end
		end
	end
end

function GetProteccSpace()
	for j = 0, 7 do
		for i = 0, 7 do
			--Return the first fitting one, don't need to pick a random fitting positions among all possible
			local curr = Point(i, j)
			if not Board:IsBlocked(curr, PATH_PROJECTILE) and
					--[[
					not Board:IsPod(curr) and
					Board:GetItem(curr) == nil and
					]]
					Board:IsTerrain(curr, TERRAIN_ROAD) then
				LOG("--------- GetProteccSpace() -> curr: "..curr:GetString())
				return curr
			end
		end
	end
	LOG("GetProteccSpace() -> couldn't find a fitting space :( -> returning Point(-1, -1)")
	return Point(-1, -1) --eh
end


local function computeGridMechProtecc(p1, se)
	if se == nil or se.effect == nil then return end

	--took that safety from my hell breachers protecc
    if not se.q_effect:empty() then
        --LOG("HERE!!! queued effect detected")
        return
    end

    for i = 1, se.effect:size() do
        local damageRedirected = 0
        local spaceDamage = se.effect:index(i)
        
        if spaceDamage.iDamage > 0 and Board:IsBuilding(spaceDamage.loc) then
        	LOG("-------------- spaceDamage.loc: "..spaceDamage.loc:GetString())
        	local origin = spaceDamage.loc
            local proteccPawn = Board:GetPawn(origin)

            if proteccPawn ~= nil and proteccPawn:GetType() == "truelch_GridMech" then
            	LOG("------ Protected by a Grid Mech!")
                damageRedirected = damageRedirected + spaceDamage.iDamage
                spaceDamage.iDamage = 0
                spaceDamage.sImageMark = "combat/icons/icon_guard_glow.png" --moved the icon to the protected building
                local id = proteccPawn:GetId()                

                if damageRedirected > 0 then
                    se:AddScript(string.format([[Board:AddAlert(%s, "Grid Protection")]], spaceDamage.loc:GetString()))
                	--V1
                	--local redir = SpaceDamage(spaceDamage.loc, damageRedirected)
                	--se:AddDamage(redir)

                	--V2: Add safe damage (+ trying to apply it on a different space)                                        
                    local testSpace = GetProteccSpace()
                    --local testSpace = Point(-1, -1)
                    local redir = SpaceDamage(testSpace, damageRedirected)
                    redir.sImageMark = "combat/icons/icon_resupply.png"
                    redir.bHide = true

                    LOG(string.format("--------------- Before: testSpace: %s, origin: %s", testSpace:GetString(), origin:GetString()))
                    
                    se:AddScript(string.format("Board:GetPawn(%s):SetSpace(%s)", tostring(id), testSpace:GetString()))
                	se:AddSafeDamage(redir)
                    se:AddScript(string.format("Board:GetPawn(%s):SetSpace(%s)", tostring(id), origin:GetString()))

                    LOG(string.format("--------------- After: testSpace: %s, origin: %s", testSpace:GetString(), origin:GetString()))

                    --V3: Pawn:ApplyDamage()
                    --https://github.com/itb-community/ITB-ModLoader/wiki/Pawn#applyDamage
                    --se:AddScript(string.format("Board:GetPawn(%s):ApplyDamage(SpaceDamage(%s, %s))", spaceDamage.loc:GetString(), spaceDamage.loc:GetString(), tostring(damageRedirected)))
                end
            end
        end
    end
end


--V2
local function EVENT_onSkillEnd(mission, pawn, weaponId, p1, p2)
	
end


--V1
local function EVENT_onSkillBuild(mission, pawn, weaponId, p1, p2, skillEffect)
	computeGridMechProtecc(p1, skillEffect)
end

local function EVENT_onFinalEffectBuild(mission, pawn, weaponId, p1, p2, p3, skillEffect)
	computeGridMechProtecc(p1, skillEffect)
end

modapiext.events.onSkillBuild:subscribe(EVENT_onSkillBuild)
modapiext.events.onFinalEffectBuild:subscribe(EVENT_onFinalEffectBuild)


------------------------
--- Dislocation Mech ---
------------------------

truelch_DislocationMech = Pawn:new {
	Name = "Dislocation Mech",
	Class = "Ranged",
	Health = 2,
	MoveSpeed = 3,
	Image = "MechArt",
	ImageOffset = palette,
	--ImageOffset = 9,
	SkillList = { "truelch_RiftInducer", "Brute_Tankmech" },
	SoundLocation = "/enemy/burrower_2/",
	DefaultTeam = TEAM_PLAYER,
	ImpactMaterial = IMPACT_METAL,
	Massive = true,
}

--I didn't added that at first, but I might need that in the end
local oldMove = Move.GetTargetArea
function Move:GetTargetArea(p, ...)
	local mover = Board:GetPawn(p)
	if mover and mover:GetType() == "truelch_GridMech" then
		--LOG("------- Grid Mech special move")

		local ret = PointList()

		local moveSpeed = mover:GetMoveSpeed()

		--Test
		for j = 0, 7 do
			for i = 0, 7 do
				local curr = Point(i, j)
				if Board:IsBuilding(curr) and p:Manhattan(curr) <= moveSpeed and p ~= curr then
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