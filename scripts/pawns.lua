--------------------------
--- Imports and traits ---
--------------------------

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
    desc_text = "Instead of moving, teleports to a building in move range.\nWhile the Grid Mech is alive, the building is immune to damage.\nThe Grid Mech is also immune to Web."
}

--------------------
--- Mission Data ---
--------------------

local function isMission()
	local mission = GetCurrentMission()

	return true
		and isGame()
		and mission ~= nil
		and mission ~= Mission_Test
end

local function missionData()
	local mission = GetCurrentMission()

	if mission.truelch_RuleBreakers == nil then
		mission.truelch_RuleBreakers = {}
	end

	--missionData().sawStatus[pawnId] =
	---> 0: sawblade is on the mech
	---> 1: sawblade is dead
	---> <sawblade's id>: sawblade is alive!
	if mission.truelch_RuleBreakers.sawStatus == nil then
		mission.truelch_RuleBreakers.sawStatus = {}
	end

	return mission.truelch_RuleBreakers
end

----------------
--- Saw Mech ---
----------------

truelch_SawbladeMech = Pawn:new {
	Name = "Sawblade Mech",
	Class = "Brute",
	Health = 3,
	MoveSpeed = 4, --idea: 3 + 1 if the sawblade isn't on the mech?
	Image = "MechPierce",
	ImageOffset = palette,
	SkillList = { "truelch_SawbladeLauncher" --[[, "truelch_debug_weapon"]] },
	SoundLocation = "/mech/brute/pierce_mech/",
	DefaultTeam = TEAM_PLAYER,
	ImpactMaterial = IMPACT_METAL,
	Massive = true,
}

local function isEquippedWithSawbladeLauncher(mech)
	return mech ~= nil and (mech:IsWeaponPowered("truelch_SawbladeLauncher") or
		mech:IsWeaponPowered("truelch_SawbladeLauncher_A") or
		mech:IsWeaponPowered("truelch_SawbladeLauncher_B") or
		mech:IsWeaponPowered("truelch_SawbladeLauncher_AB"))
end

local function isSawbladePos(curr)
	local pawn = Board:GetPawn(curr)
	return pawn ~= nil and (pawn:GetType() == "truelch_Sawblade" or pawn:GetType() == "truelch_Sawblade_A")
end

--[[
The idea is that if the sawblade's pos is adjacent to a tile in the path
]]
local function isReachable(pawn, sawbladePos)
	--LOG(" ============= isReachable() =============")
	local moveSpeed = pawn:GetMoveSpeed()
	--LOG("------------ moveSpeed: "..tostring(moveSpeed))
	local reachable = extract_table(Board:GetReachable(pawn:GetSpace(), pawn:GetMoveSpeed(), pawn:GetPathProf()))

	for i = 1, #reachable do
		--LOG("------------ i: "..tostring(i))
		local pos = reachable[i]
		--LOG("------------ pos: "..pos:GetString())		

		local yes = false
		for dir = DIR_START, DIR_END do
			--LOG("------------ dir: "..tostring(dir))
			local adj = pos + DIR_VECTORS[dir]
			--LOG("------------ adj: "..adj:GetString())
			if adj == sawbladePos then
				--LOG("------------ yes!")
				yes = true
			end
		end

		--Compute point distance
		--local path = Board:GetPath(pawn:GetSpace(), pos, pawn:GetPathProf()):size()
		local dist = Board:GetPath(pawn:GetSpace(), pos, pawn:GetPathProf()):size()
		--Maybe I can get the length of the path
		--dist = #path --no

		--[[
		for i = 1, #reachable do
			local pathPoint = reachable[i]
			LOG("------------ dist = dist + 1")
			dist = dist + 1
		end	
		]]	

		--LOG("------------ dist: "..tostring(dist))

	    if dist + 1 <= moveSpeed and yes then
	    	--LOG("------------ return true")
	    	return true
	    end
	end

	--LOG("------------ return false")

	return false
end

--Not just Sawblade Mech, but a Mech that is equipped with a truelch_SawbladeLauncher
local oldMove = Move.GetTargetArea
function Move:GetTargetArea(p, ...)	
	local mover = Board:GetPawn(p)
	if mover and isEquippedWithSawbladeLauncher(mover) then

		--LOG("---------------- A")
		local ret = PointList()
		--Add original move
		local reachable = extract_table(Board:GetReachable(mover:GetSpace(), mover:GetMoveSpeed(), mover:GetPathProf()))
		--for _, curr in ipairs(reachable) do
		for i = 1, #reachable do
			local curr = reachable[i]
			--LOG("---------------- iteration reachable")
			ret:push_back(curr)
		end

		--LOG("---------------- B")

		local moveSpeed = mover:GetMoveSpeed()
		for j = 0, 7 do
			for i = 0, 7 do
				local curr = Point(i, j)
				if isSawbladePos(curr) and isReachable(mover, curr) then
					ret:push_back(curr)
				end
			end
		end

		return ret
	end

	return oldMove(self, p, ...)
end

--[[
TODO:
- handle undo move
- make the logic for retrieving sawblade (add animation, set mission data)
- what if the sawblade comes from another Mech?
]]

local oldMove = Move.GetSkillEffect
function Move:GetSkillEffect(p1, p2, ...)
	local mover = Board:GetPawn(p1)
	if mover and isEquippedWithSawbladeLauncher(mover) and isSawbladePos(p2) then
		local ret = SkillEffect()

		local sawblade = Board:GetPawn(p2)

		sawblade:SetSpace(Point(-1, -1))
		--I need to maybe keep it alive if I undo move, no?

		--[[
		if Board:GetPawn(p2) ~= nil then
			LOG("----------- Kill sawblade")
			ret:AddScript(string.format("Board:GetPawn(%s):Kill()", p2:GetString()))

		else
			LOG("----------- WHAAAAAAT")
		end
		]]

		ret:AddMove(Board:GetPath(p1, p2, mover:GetPathProf()), FULL_DELAY)

		ret:AddScript(string.format([[Board:AddAlert(%s, "SAWBLADE RETRIEVED")]], p2:GetString()))

		--
		
		return ret
	end

	return oldMove(self, p1, p2, ...)
end


local function EVENT_onPawnUndoMove(mission, pawn, undonePosition)
	LOG(pawn:GetMechName().." move was undone! Was at: "..undonePosition:GetString()..", returned to: "..pawn:GetSpace():GetString())
	
end

modapiext.events.onPawnUndoMove:subscribe(EVENT_onPawnUndoMove)


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
	SkillList = { "truelch_GridShield", "truelch_GridDischarge" },
	SoundLocation = "/enemy/bouncer_2/",
	DefaultTeam = TEAM_PLAYER,
	ImpactMaterial = IMPACT_METAL,
	Massive = true,
	Flying = true, --not really necessary in the end?
	IgnoreSmoke = true,
	--WebImmune = true, --I think you need to do it by script
	Pushable = false, --maybe?
	--Corpse = false, --test?
}

--Taken from Generic's Leaper (and changed to an event because why not)
local function EVENT_onPawnGrappled(mission, pawn, isGrappled)
	LOG("EVENT_onPawnGrappled")
	if isGrappled and pawn:GetType() == "truelch_GridMech" then --If we're grappled and it's our truelch_GridMech
		--If removing the web right away it looks really weird (try it if you want). So we'll wait about half a second with this

		local oldTerrain = Board:GetTerrain(pawn:GetSpace())

		modApi:scheduleHook(550, function()
			local space = pawn:GetSpace() --Store the space so we can move it back later
			Board:AddAlert(space, "WEB IMMUNE") --This will play an alert when it happens
			--It's entirely optional, remove it if you don't like it
			pawn:SetSpace(Point(-1, -1)) --Move the pawn to Point(-1,-1)

			--Test
			Board:SetTerrain(space, TERRAIN_ROAD)

			modApi:runLater(function() --This runs a function one frame later so things get updated
				pawn:SetSpace(space) --Move the pawn back, after that one frame. The web will be gone

				modApi:runLater(function()
					Board:SetTerrain(space, oldTerrain)
				end)
			end)
		end)
	end
end

modapiext.events.onPawnIsGrappled:subscribe(EVENT_onPawnGrappled)


function getProteccSpace()
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
				--LOG("--------- getProteccSpace() -> curr: "..curr:GetString())
				return curr
			end
		end
	end
	LOG("getProteccSpace() -> couldn't find a fitting space :( -> returning Point(-1, -1)")
	return Point(-1, -1) --eh
end


local function computeGridMechProtecc(p1, se)
	--LOG("=================== computeGridMechProtecc ===================")
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
        	--LOG("-------------- spaceDamage.loc: "..spaceDamage.loc:GetString())
        	local origin = spaceDamage.loc
            local proteccPawn = Board:GetPawn(origin)

            if proteccPawn ~= nil and proteccPawn:GetType() == "truelch_GridMech" then
            	--LOG("-------------- Protected by a Grid Mech!")
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
                    local testSpace = getProteccSpace()
                    --local testSpace = Point(-1, -1)
                    local redir = SpaceDamage(testSpace, damageRedirected)
                    redir.sImageMark = "combat/icons/icon_resupply.png"
                    redir.bHide = true

                    --LOG(string.format("-------------- Before: testSpace: %s, origin: %s", testSpace:GetString(), origin:GetString()))
                    
                    se:AddScript(string.format("Board:GetPawn(%s):SetSpace(%s)", tostring(id), testSpace:GetString()))
                	se:AddSafeDamage(redir)
                    se:AddScript(string.format("Board:GetPawn(%s):SetSpace(%s)", tostring(id), origin:GetString()))

                    --LOG(string.format("-------------- After: testSpace: %s, origin: %s", testSpace:GetString(), origin:GetString()))

                    --V3: Pawn:ApplyDamage()
                    --https://github.com/itb-community/ITB-ModLoader/wiki/Pawn#applyDamage
                    --se:AddScript(string.format("Board:GetPawn(%s):ApplyDamage(SpaceDamage(%s, %s))", spaceDamage.loc:GetString(), spaceDamage.loc:GetString(), tostring(damageRedirected)))
                end
            end
        end
    end
end

local function EVENT_onSkillBuild(mission, pawn, weaponId, p1, p2, skillEffect)
	computeGridMechProtecc(p1, skillEffect)
end

local function EVENT_onFinalEffectBuild(mission, pawn, weaponId, p1, p2, p3, skillEffect)
	computeGridMechProtecc(p1, skillEffect)
end

modapiext.events.onSkillBuild:subscribe(EVENT_onSkillBuild)
modapiext.events.onFinalEffectBuild:subscribe(EVENT_onFinalEffectBuild)

local oldMove = Move.GetTargetArea
function Move:GetTargetArea(p, ...)
	local mover = Board:GetPawn(p)
	if mover and mover:GetType() == "truelch_GridMech" then
		local ret = PointList()
		local moveSpeed = mover:GetMoveSpeed()
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
	SkillList = { "truelch_RiftInducer" },
	SoundLocation = "/enemy/burrower_2/",
	DefaultTeam = TEAM_PLAYER,
	ImpactMaterial = IMPACT_METAL,
	Massive = true,
}

