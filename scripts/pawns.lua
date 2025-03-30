--------------------------
--- Imports and traits ---
--------------------------

local mod = mod_loader.mods[modApi.currentMod]
--local mod = modApi:getCurrentMod() --what's the best alternative?

local resourcePath = mod.resourcePath
local scriptPath = mod.scriptPath

local functions = require(scriptPath.."functions")

--local mechPath = resourcePath .."img/mechs/"
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


----------------
--- Saw Mech ---
----------------

truelch_SawbladeMech = Pawn:new{
	Name = "Sawblade Mech",
	Class = "Brute",
	Health = 3,
	MoveSpeed = 15,
	--MoveSpeed = 4, --idea: 3 + 1 if the sawblade isn't on the mech?
	Image = "mech_sawblade", --"MechPierce"
	ImageOffset = palette,
	--SkillList = { "truelch_SawbladeLauncher" },
	--SkillList = { "truelch_SawbladeLauncher", "truelch_test_weapon" },
	SkillList = { "truelch_debug_weapon", "truelch_test_weapon" },
	SoundLocation = "/mech/brute/pierce_mech/",
	DefaultTeam = TEAM_PLAYER,
	ImpactMaterial = IMPACT_METAL,
	Massive = true,
}

--[[
The idea is that if the sawblade's pos is adjacent to a tile in the path
]]
local function isReachable(pawn, sawbladePos)
	local moveSpeed = pawn:GetMoveSpeed()
	local reachable = extract_table(Board:GetReachable(pawn:GetSpace(), pawn:GetMoveSpeed(), pawn:GetPathProf()))
	for i = 1, #reachable do
		local pos = reachable[i]
		local yes = false
		for dir = DIR_START, DIR_END do
			local adj = pos + DIR_VECTORS[dir]
			if adj == sawbladePos then
				yes = true
			end
		end

		--Compute point distance
		local dist = Board:GetPath(pawn:GetSpace(), pos, pawn:GetPathProf()):size()

	    if dist + 1 <= moveSpeed and yes then
	    	return true
	    end
	end
	return false
end

--Not just Sawblade Mech, but any Mech equipped with a truelch_SawbladeLauncher
local oldMove = Move.GetTargetArea
function Move:GetTargetArea(p, ...)	
	local mover = Board:GetPawn(p)

	--local status = missionData().sawStatus[mover:GetId()]
	local amount = functions:getSawbladeAmount(mover)

	if mover and functions:isEquippedWithSawbladeLauncher(mover) and (amount == nil or amount <= 0) then
		local ret = PointList()

		--Add original move
		local reachable = extract_table(Board:GetReachable(mover:GetSpace(), mover:GetMoveSpeed(), mover:GetPathProf()))
		for i = 1, #reachable do
			local curr = reachable[i]
			ret:push_back(curr)
		end

		local moveSpeed = mover:GetMoveSpeed()
		for j = 0, 7 do
			for i = 0, 7 do
				local curr = Point(i, j)
				if (functions:isSawbladePos(curr) or functions:isReinforcedSawbladePos(curr)) and isReachable(mover, curr) then
					ret:push_back(curr)
				end
			end
		end

		return ret
	end

	return oldMove(self, p, ...)
end


--Arguments
local truelch_testMover_mover = nil --mover
local truelch_testMover_sawblade = nil --sawbladehttps://www.twitch.tv/tastelesstv

function truelch_testMover()
	table.insert(functions:missionData().retrMoveData, { truelch_testMover_mover:GetId(), truelch_testMover_sawblade:GetId() } )
end

--[[
function truelch_testMover2()
	--functions:missionData().sawStatus[truelch_testMover_mover:GetId()] = 0
	--functions:missionData().
end
]]

local oldMove = Move.GetSkillEffect
function Move:GetSkillEffect(p1, p2, ...)
	local mover = Board:GetPawn(p1)
	local ret = SkillEffect()

	if mover and functions:isEquippedWithSawbladeLauncher(mover) and (functions:isSawbladePos(p2) or functions:isReinforcedSawbladePos(p2)) then
		truelch_testMover_mover = mover
		truelch_testMover_sawblade = Board:GetPawn(p2)
		ret:AddScript("truelch_testMover()")
		ret:AddScript(string.format("Board:GetPawn(%s):SetSpace(Point(-1, -1))", p2:GetString()))
		ret:AddMove(Board:GetPath(p1, p2, mover:GetPathProf()), FULL_DELAY)
		ret:AddScript(string.format([[Board:AddAlert(%s, "SAWBLADE RETRIEVED")]], p2:GetString()))
		--ret:AddScript("truelch_testMover2()")
		ret:AddScript(string.format("truelch_addSawblade(Board:GetPawn(%s), 1)", p2:GetString()))
		return ret
	else
		ret:AddMove(Board:GetPath(p1, p2, mover:GetPathProf()), FULL_DELAY)
		return ret
	end

	return oldMove(self, p1, p2, ...)
end


local function EVENT_onPawnUndoMove(mission, pawn, undonePosition)
	if not pawn:IsMech()
			or not functions:isEquippedWithSawbladeLauncher(pawn)
			or functions:getSawbladeAmount(pawn) == nil then
		LOG("EVENT_onPawnUndoMove -> check return")
		return
	end

	--TODO: what if the mech already has a sawblade on it?

	--[[
	status:
	- nil: error
	- 0: sawblade is on the mech
	- 1: no sawblade on the mec
	- >= 1: not used anymore
	]]

	local amount = functions:getSawbladeAmount(pawn)
	--LOG("------------------ amount: "..tostring(amount))

	if amount == nil or amount == 0 then
		--LOG("------------------ amount == 0 (meaning that we don't actually have a sawblade)")
		return
	end

	--LOG(save_table(GetCurrentMission().truelch_RuleBreakers.retrMoveData)) --for the console in-game

	-- CHECK --->
	if functions:missionData().retrMoveData == nil then
		--LOG("------------------ missionData().retrMoveData == nil :(")
		return
	end

	local count = 0
	for _ in pairs(functions:missionData().retrMoveData) do
		count = count + 1
	end

	--LOG("------------------ count: "..tostring(count))

	if count == 0 then
		return
	end
	-- <--- CHECK

	local mechId = functions:missionData().retrMoveData[count][1]
	local sawbId = functions:missionData().retrMoveData[count][2]

	local mech = Board:GetPawn(mechId)
	local sawb = Board:GetPawn(sawbId)

	if pawn:GetId() == mech:GetId() and
			mech ~= nil and
			sawb ~= nil then
		sawb:SetSpace(undonePosition)
		--functions:missionData().sawStatus[pawn:GetId()] = 1
		functions:addSawblade(pawn, -1)

		--Remove
		table.remove(functions:missionData().retrMoveData, count) --table.getn(missionData().retrMoveData) --would this work?		
	end
end

modapiext.events.onPawnUndoMove:subscribe(EVENT_onPawnUndoMove)


-----------------
--- Grid Mech ---
-----------------

truelch_GridMech = Pawn:new{
	Name = "Grid Mech",
	Class = "Science",
	Health = 3,
	MoveSpeed = 8, --4,
	Image = "mech_grid",
	ImageOffset = palette,
	SkillList = { "truelch_GridShield", "truelch_GridDischarge" },
	--SkillList = { "truelch_GridShield", "truelch_debug_weapon" },
	SoundLocation = "/enemy/mosquito_2/",
	DefaultTeam = TEAM_PLAYER,
	ImpactMaterial = IMPACT_METAL,
	Massive = true,
	Flying = true,
	IgnoreSmoke = true,
	Pushable = false,
	LargeShield = true,
}

--Taken from Generic's Leaper (and changed to an event because why not)
local function EVENT_onPawnGrappled(mission, pawn, isGrappled)
	--LOG("EVENT_onPawnGrappled")
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
					Board:IsTerrain(curr, TERRAIN_ROAD) then
				return curr
			end
		end
	end
	LOG("getProteccSpace() -> couldn't find a fitting space :( -> returning Point(-1, -1)")
	return Point(-1, -1) --eh
end

local foo_damageRedirected = -1
local foo_origin = Point(-1, -1)
local foo_pawnId = -1
function fooProteccQueued()
	--LOG("fooProteccQueued()")

	if foo_damageRedirected == -1 or foo_origin == Point(-1, -1) or foo_pawnId == -1 or functions == nil or not functions:isMission() then
		LOG("fooProteccQueued() --- ERROR ---> RETURN")
		return
	end

	table.insert(functions:missionData().proteccData[foo_pawnId], { foo_origin.x, foo_origin.y, foo_damageRedirected })

	local count = 0
	for _, data in ipairs(functions:missionData().proteccData[foo_pawnId]) do
		count = count + 1
	end
	--LOG("count: "..tostring(count))
end

local function fooProtecc(pawn, se, effects, isQueued)
	--LOGF("fooProtecc(pawn: %s, isQueued: %s)", pawn:GetMechName(), tostring(isQueued))
	if not functions:isMission() then
		return
	end
	if isQueued then
		--LOG("fooProtecc - isQueued")
		functions:missionData().proteccData[pawn:GetId()] = {}
	end

    for i = 1, effects:size() do
    	--LOG("fooProtecc -> loop i: "..tostring(i))
        local damageRedirected = 0
        local spaceDamage = effects:index(i)        
        if spaceDamage.iDamage > 0 and Board:IsBuilding(spaceDamage.loc) then
        	--LOG("spaceDamage.iDamage: "..tostring(spaceDamage.iDamage))
        	local origin = spaceDamage.loc
        	--[[
        	if not isQueued then
        		LOG("Truelch -------------- spaceDamage.loc: "..spaceDamage.loc:GetString())
        	end
        	]]
            local proteccPawn = Board:GetPawn(origin)
            if proteccPawn ~= nil and proteccPawn:GetType() == "truelch_GridMech" then
            	--LOG("if proteccPawn ~= nil and proteccPawn:GetType() == truelch_GridMech")
                damageRedirected = damageRedirected + spaceDamage.iDamage
                spaceDamage.iDamage = 0
                spaceDamage.sImageMark = "combat/icons/icon_guard_glow.png" --moved the icon to the protected building
                local id = proteccPawn:GetId()
                if damageRedirected > 0 then
                	--LOG("if damageRedirected > 0 then")
                	if not isQueued then
	                    local proteccAnim = SpaceDamage(origin, 0)
	                    proteccAnim.sAnimation = "truelch_anim_grid_protecc"
	                    se:AddDamage(proteccAnim)
	                    se:AddScript(string.format([[Board:AddAlert(%s, "GRID PROTECTION")]], spaceDamage.loc:GetString()))
	                    local testSpace = getProteccSpace()
	                    local redir = SpaceDamage(testSpace, damageRedirected)
	                    redir.bHide = true
	                    se:AddScript(string.format("Board:GetPawn(%s):SetSpace(%s)", tostring(id), testSpace:GetString()))
	                	se:AddSafeDamage(redir)
	                    se:AddScript(string.format("Board:GetPawn(%s):SetSpace(%s)", tostring(id), origin:GetString()))
	                    LOGF("Truelch -------------- IS NOT QUEUED -> origin: %s, spaceDamage.loc: %s", origin:GetString(), spaceDamage.loc:GetString())
	                    --Sometimes, origin will have a very random value, like: Point( 1869373284, 1919247457 ) and after that, it's a correct value.
	                    --This problem vanished after I put LOGs wtf
                	else
                		--LOG("-------------- IS QUEUED")
                		--[[
						functions:missionData().proteccData = {
							[107] = { --Firefly's id
								[1] = 2 --x
								[2] = 4 --y
								[3] = 1 --damage value
							}
						}
						]]

                		--TODO / WIP
                		--Add all damage (it can be an AoE!)
                		--[[
                		LOGF("----- fooProtecc() -> putting data: pawn's id: %s, pos: %s, damage: %s",
                			tostring(pawn:GetId()), origin:GetString(), tostring(damageRedirected))
            			]]
						--table.insert(functions:missionData().proteccData[pawn:GetId()], { origin.x, origin.y, damageRedirected })
						--se:AddScript([[table.insert(functions:missionData().proteccData[pawn:GetId()], { origin.x, origin.y, damageRedirected })]])
						foo_origin = origin
						foo_damageRedirected = damageRedirected
						foo_pawnId = pawn:GetId()
						--se:AddScript("fooProteccQueued()")
						fooProteccQueued()
                	end

                end
            end
        end
    end
end

local function computeGridMechProtecc(pawn, se)
	--LOG("computeGridMechProtecc")
	if se == nil or pawn == nil then return end
	fooProtecc(pawn, se, se.effect,   false)
	fooProtecc(pawn, se, se.q_effect, true)
end

local function EVENT_onSkillBuild(mission, pawn, weaponId, p1, p2, skillEffect)
	--LOG(">>> (EVENT_onSkillBuild(weaponId: "..tostring(weaponId)..")")
	computeGridMechProtecc(pawn, skillEffect)
end
modapiext.events.onSkillBuild:subscribe(EVENT_onSkillBuild)

local function EVENT_onFinalEffectBuild(mission, pawn, weaponId, p1, p2, p3, skillEffect)
	computeGridMechProtecc(pawn, skillEffect)
end
modapiext.events.onFinalEffectBuild:subscribe(EVENT_onFinalEffectBuild)


local function EVENT_onNextTurn(mission)
	if Game:GetTeamTurn() == TEAM_PLAYER then
		--Clear protecc data
		functions:missionData().proteccData = {}

		--Final mission second phase only: remove tentacle location for Grid Mech(s) on building(s)
		if GetCurrentMission().ID == "Mission_Final_Cave" and GetCurrentMission().LiveEnvironment.Locations ~= nil then
			for index, point in ipairs(GetCurrentMission().LiveEnvironment.Locations) do
				for i = 0, 2 do
					local mech = Board:GetPawn(i)
					if mech ~= nil and mech:IsMech() and Board:IsBuilding(mech:GetSpace()) and
						mech:GetSpace() == point then
						table.remove(GetCurrentMission().LiveEnvironment.Locations, index)
						index = index - 1
					end
				end
			end
		end
	end
end
modApi.events.onNextTurn:subscribe(EVENT_onNextTurn)

--[[
functions:missionData().proteccData = {
	[107] = { --Firefly's id
		[1] = 2 --x
		[2] = 4 --y
		[3] = 1 --damage value
	}
}
]]
local function fooSkillReleased(pawn)
	if pawn == nil or not functions:isMission() or functions:missionData().proteccData == nil or functions:missionData().proteccData[pawn:GetId()] == nil then
		return
	end

	for _, data in ipairs(functions:missionData().proteccData[pawn:GetId()]) do
		local x = data[1]
		local y = data[2]
		local pos = Point(x, y)
		local damageRedirected = data[3]
		--LOGF("=== fooSkillReleased -> pos: %s, damage: %s", pos:GetString(), tostring(damageRedirected))

		--Look for Grid Mechs
		local mech = Board:GetPawn(pos)
		if mech ~= nil and mech:GetType() == "truelch_GridMech" and Board:IsBuilding(pos) and damageRedirected > 0 then
			--Get the damage and apply to the mech
			--Note that I needed to move temporarily the mech elsewhere to be able to deal damage to it

			local se = SkillEffect()

			--Board:AddAlert(pos, "Grid Protection")
			local testSpace = getProteccSpace()
			mech:SetInvisible(true)
			mech:SetSpace(testSpace)
			local redir = SpaceDamage(testSpace, damageRedirected)
			se:AddSafeDamage(redir)
			Board:AddEffect(se)

			if mech:IsShield() and damageRedirected ~= DAMAGE_DEATH then
				--modApi:scheduleHook(50, function()
				modApi:scheduleHook(550, function()
					mech:SetShield(false)
					mech:SetSpace(pos)
					mech:SetInvisible(false)
				end)
			else
				--in any case -> NO
				functions:missionData().proteccReloc = { mech:GetId(), pos.x, pos.y } --pleaseworkpleasework
			end


		end

		--Clear data: NOPE, clear once all effects have been resolved,
		--otherwise, we'll clear the data the first time an enemy release its attack
		--So we want to clean on next turn (player turn) - or something like that
	end
end


local EVENT_onQueuedSkillEnded = function(mission, pawn, weaponId, p1, p2)
	fooSkillReleased(pawn)
end
modapiext.events.onQueuedSkillEnd:subscribe(EVENT_onQueuedSkillEnded)

--Test
local EVENT_onQueuedSkillStarted = function(mission, pawn, weaponId, p1, p2)
	--Maybe start the anim here? idk
	if pawn == nil or not functions:isMission() or functions:missionData().proteccData == nil or functions:missionData().proteccData[pawn:GetId()] == nil then
		return
	end

	for _, data in ipairs(functions:missionData().proteccData[pawn:GetId()]) do
		local x = data[1]
		local y = data[2]
		local pos = Point(x, y)
		local damageRedirected = data[3]

		--Maybe play a longer animation if the Mech is shielded?
		if damageRedirected > 0 then
			local se = SkillEffect()
			local proteccAnim = SpaceDamage(pos, 0)
			proteccAnim.sAnimation = "truelch_anim_grid_protecc"
			se:AddDamage(proteccAnim)
			Board:AddEffect(se)
		end
	end
end
modapiext.events.onQueuedSkillStart:subscribe(EVENT_onQueuedSkillStarted)


local EVENT_onPawnDamaged = function(mission, pawn, damageTaken)

	if not functions:isMission() or functions:missionData().proteccReloc == nil or
			functions:missionData().proteccReloc[1] == nil or
			functions:missionData().proteccReloc[2] == nil or
			functions:missionData().proteccReloc[3] == nil then
		return
	end

	LOGF("EVENT_onPawnDamaged(pawn: %s, damageTaken: %s)", pawn:GetMechName(), tostring(damageTaken))

	local id = functions:missionData().proteccReloc[1]
	local pos = Point(functions:missionData().proteccReloc[2], functions:missionData().proteccReloc[3])

	local pawn = Board:GetPawn(id)
	if pawn ~= nil then
		--modApi:scheduleHook(550, function()
			if pawn:IsShield() then
				pawn:SetShield(false)
			end
			pawn:SetSpace(pos) --test
			pawn:SetInvisible(false)
			--Board:AddAlert(pos, "GRID PROTECTION")
		--end)
	end

	--Clean data in any case
	functions:missionData().proteccReloc = nil
end
modapiext.events.onPawnDamaged:subscribe(EVENT_onPawnDamaged)



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

truelch_DislocationMech = Pawn:new{
	Name = "Dislocation Mech",
	Class = "Ranged",
	Health = 2,
	MoveSpeed = 15, --2, --0.0.7 nerf
	Image = "mech_dislocation",
	ImageOffset = palette,
	SkillList = { "truelch_RiftInducer", "truelch_test_weapon" },
	SoundLocation = "/mech/distance/artillery/",
	DefaultTeam = TEAM_PLAYER,
	ImpactMaterial = IMPACT_METAL,
	Massive = true,
}