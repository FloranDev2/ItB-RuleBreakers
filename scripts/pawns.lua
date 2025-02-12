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

local function isGame()
    return true
        and Game ~= nil
        and GAME ~= nil
end

local function isMission()
	local mission = GetCurrentMission()

	return true
		and isGame()
		and mission ~= nil
		and mission ~= Mission_Test
end

local function missionData()
	local mission = GetCurrentMission()

	if mission == nil then
		return nil
	end

	if mission.truelch_RuleBreakers == nil then
		mission.truelch_RuleBreakers = {}
	end

	---------------------
	--- SAWBLADE MECH ---
	---------------------

	--missionData().sawStatus[pawnId] =
	---> 0: sawblade is on the mech
	---> 1: sawblade is dead
	---> <sawblade's id>: sawblade is alive!
	if mission.truelch_RuleBreakers.sawStatus == nil then
		mission.truelch_RuleBreakers.sawStatus = {}
	end

	--[[
	List of pairs of pawns: first is the mech and second is the sawblade
	Example:
	missionData().retrMoveData = { { 0, 110 }, { 1, 127 } }
	Here, the pawn at id 0 (first mech) equipped with a sawblade moved to the position of a sawblade that has an id of 110
	Then, the pawn at id 1 (second mech) also equipped with a sawblade launcher moved to the position of a sawblade that has an id of 127
	Note that any mech equipped by a sawblade launcher can retrieve any sawblade (so you can retrieve sawblades launched by other mechs)
	]]
	if mission.truelch_RuleBreakers.retrMoveData == nil then
		mission.truelch_RuleBreakers.retrMoveData = {}
	end


	-----------------
	--- GRID MECH ---
	-----------------

	--[[
	Are Point serializable? I might just put coordinates in the mission data
	Another issue: the damage: should I save status (fire, acid, etc.) or just the damage value?
	missionData().proteccData[enemyId] = { p2.x, p2.y, damage }
	Another thing to note is that it seems that firefly don't target directly the tile but a front it tile (direction).

	WHAT IF A VEK HAS AN AOE EFFECT AND THERE ARE MULTIPLE GRID MECHS AFFECTED?!

	Example:
	missionData().proteccData = {
		[107] = { --Firefly1
			[1] = 2 --x
			[2] = 4 --y
			[3] = 1 --damage value
		}
		[110] = {
			[1] = 2 --x
			[2] = 4 --y
			[3] = 1 --damage value
		}
	}
	]]
	if mission.truelch_RuleBreakers.proteccData == nil then
		mission.truelch_RuleBreakers.proteccData = {}
	end

	--- RETURN
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
	SkillList = { "truelch_SawbladeLauncher", --[["truelch_debug_weapon"]] },
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

local function isSawbladePos(curr, showLogs)
	local pawn = Board:GetPawn(curr)

	if showLogs == true then
		LOG("------------ isSawbladePos")
		local cond1 = pawn ~= nil
		if pawn ~= nil then
			LOG("------------ cond1 pawn exists -> pawn type: "..pawn:GetType())
			local cond2 = pawn:GetType() == "truelch_Sawblade"
			local cond3 = pawn:GetType() == "truelch_Sawblade_A"
			LOG("------------ cond2: "..tostring(cond2))
			LOG("------------ cond3: "..tostring(cond3))
		else
			LOG("------------ pawn is nil!")
		end
	end

	local ret = pawn ~= nil and (pawn:GetType() == "truelch_Sawblade" or pawn:GetType() == "truelch_Sawblade_A")

	if showLogs == true then
		LOG("------------ ret: "..tostring(ret))
	end

	return ret
end

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

--Not just Sawblade Mech, but a Mech that is equipped with a truelch_SawbladeLauncher
local oldMove = Move.GetTargetArea
function Move:GetTargetArea(p, ...)	
	local mover = Board:GetPawn(p)

	local status = missionData().sawStatus[mover:GetId()]

	if mover and isEquippedWithSawbladeLauncher(mover) and (status == nil or status ~= 0) then
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

--Arguments
--[[
local truelch_testMover_p1 = nil --p1
local truelch_testMover_p2 = nil --p2
]]
local truelch_testMover_mover = nil --mover
local truelch_testMover_sawblade = nil --sawbladehttps://www.twitch.tv/tastelesstv

function truelch_testMover()
	--LOG("truelch_testMover()")
	--[0] -> mech's id / [1] -> sawblade's id
	table.insert(missionData().retrMoveData, { truelch_testMover_mover:GetId(), truelch_testMover_sawblade:GetId() } )

	--LOG("save_table(GetCurrentMission().truelch_RuleBreakers)") --for the console in-game
	--LOG("TEST -> lastMovePawnId: "..tostring(missionData().lastMovePawnId))
end

function truelch_testMover2()
	missionData().sawStatus[truelch_testMover_mover:GetId()] = 0
end

local oldMove = Move.GetSkillEffect
function Move:GetSkillEffect(p1, p2, ...)
	local mover = Board:GetPawn(p1)
	local ret = SkillEffect()

	if mover and isEquippedWithSawbladeLauncher(mover) and isSawbladePos(p2) then
		truelch_testMover_mover = mover
		truelch_testMover_sawblade = Board:GetPawn(p2)
		ret:AddScript("truelch_testMover()")
		ret:AddScript(string.format("Board:GetPawn(%s):SetSpace(Point(-1, -1))", p2:GetString()))
		ret:AddMove(Board:GetPath(p1, p2, mover:GetPathProf()), FULL_DELAY)
		ret:AddScript(string.format([[Board:AddAlert(%s, "SAWBLADE RETRIEVED")]], p2:GetString()))
		ret:AddScript("truelch_testMover2()")

		--LOG("------------------ success")
		return ret
	else
		ret:AddMove(Board:GetPath(p1, p2, mover:GetPathProf()), FULL_DELAY)
		--LOG("------------------ failure")
		return ret
	end

	return oldMove(self, p1, p2, ...)
end


local function EVENT_onPawnUndoMove(mission, pawn, undonePosition)
	if not pawn:IsMech()
			or not isEquippedWithSawbladeLauncher(pawn)
			or missionData().sawStatus[pawn:GetId()] == nil then
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

	local status = missionData().sawStatus[pawn:GetId()]
	--LOG("------------------ status: "..tostring(status))

	if status == 1 then
		--LOG("------------------ status == 1 (meaning that we don't actually have a sawblade)")
		return
	end

	--LOG(save_table(GetCurrentMission().truelch_RuleBreakers.retrMoveData)) --for the console in-game

	-- CHECK --->
	if missionData().retrMoveData == nil then
		--LOG("------------------ missionData().retrMoveData == nil :(")
		return
	end

	local count = 0
	for _ in pairs(missionData().retrMoveData) do
		count = count + 1
	end

	--LOG("------------------ count: "..tostring(count))

	if count == 0 then
		return
	end
	-- <--- CHECK

	local mechId = missionData().retrMoveData[count][1]
	local sawbId = missionData().retrMoveData[count][2]

	local mech = Board:GetPawn(mechId)
	local sawb = Board:GetPawn(sawbId)

	if pawn:GetId() == mech:GetId() and
			mech ~= nil and
			sawb ~= nil then
		sawb:SetSpace(undonePosition)
		missionData().sawStatus[pawn:GetId()] = 1

		--Remove
		table.remove(missionData().retrMoveData, count) --table.getn(missionData().retrMoveData) --would this work?		
	end
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
	Pushable = false,
	LargeShield = true,
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

local function fooProtecc(pawn, se, effects, isQueued)

	if not isMission() then
		LOG("fooProtecc -> not mission")
		return
	end

	if isQueued then
		missionData().proteccData[pawn:GetId()] = {}
	end

    for i = 1, effects:size() do
        local damageRedirected = 0
        local spaceDamage = effects:index(i)        
        if spaceDamage.iDamage > 0 and Board:IsBuilding(spaceDamage.loc) then
        	local origin = spaceDamage.loc
            local proteccPawn = Board:GetPawn(origin)
            if proteccPawn ~= nil and proteccPawn:GetType() == "truelch_GridMech" then
                damageRedirected = damageRedirected + spaceDamage.iDamage
                spaceDamage.iDamage = 0
                spaceDamage.sImageMark = "combat/icons/icon_guard_glow.png" --moved the icon to the protected building
                local id = proteccPawn:GetId()
                if damageRedirected > 0 then
                	if not isQueued then
	                    se:AddScript(string.format([[Board:AddAlert(%s, "Grid Protection")]], spaceDamage.loc:GetString()))                                  
	                    local testSpace = getProteccSpace()
	                    local redir = SpaceDamage(testSpace, damageRedirected)
	                    redir.bHide = true                   
	                    se:AddScript(string.format("Board:GetPawn(%s):SetSpace(%s)", tostring(id), testSpace:GetString()))
	                	se:AddSafeDamage(redir)
	                    se:AddScript(string.format("Board:GetPawn(%s):SetSpace(%s)", tostring(id), origin:GetString()))
                	else
                		--[[
						missionData().proteccData = {
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
						table.insert(missionData().proteccData[pawn:GetId()], { origin.x, origin.y, damageRedirected })
                	end

                end
            end
        end
    end
end

local function computeGridMechProtecc(pawn, se)
	if se == nil or pawn == nil then return end
	fooProtecc(pawn, se, se.effect,   false)
	fooProtecc(pawn, se, se.q_effect, true)
end

local function EVENT_onSkillBuild(mission, pawn, weaponId, p1, p2, skillEffect)
	computeGridMechProtecc(pawn, skillEffect)
end
modapiext.events.onSkillBuild:subscribe(EVENT_onSkillBuild)

local function EVENT_onFinalEffectBuild(mission, pawn, weaponId, p1, p2, p3, skillEffect)
	computeGridMechProtecc(pawn, skillEffect)
end
modapiext.events.onFinalEffectBuild:subscribe(EVENT_onFinalEffectBuild)


----- JUST SOME DEBUG

local function EVENT_onNextTurn(mission)
	if Game:GetTeamTurn() == TEAM_PLAYER then
		missionData().proteccData = {}
	end
end
modApi.events.onNextTurn:subscribe(EVENT_onNextTurn)

--[[
missionData().proteccData = {
	[107] = { --Firefly's id
		[1] = 2 --x
		[2] = 4 --y
		[3] = 1 --damage value
	}
}
]]
local function fooSkillReleased(pawn)
	if pawn == nil or not isMission() or missionData().proteccData == nil or missionData().proteccData[pawn:GetId()] == nil then
		return
	end

	for _, data in ipairs(missionData().proteccData[pawn:GetId()]) do
		local x = data[1]
		local y = data[2]
		local pos = Point(x, y)
		local damageRedirected = data[3]
		--LOGF("=== fooSkillReleased -> pos: %s, damage: %s", pos:GetString(), tostring(damageRedirected))

		--Look for Grid Mechs
		local mech = Board:GetPawn(pos)
		if mech ~= nil and mech:GetType() == "truelch_GridMech" and Board:IsBuilding(pos) then
			--Get the damage and apply to the mech
			--Note that I needed to move temporarily the mech elsewhere to be able to deal damage to it

			--TODO / WIP
			local se = SkillEffect()

			--Board:AddAlert(pos, "Grid Protection")
			local testSpace = getProteccSpace()
			mech:SetSpace(testSpace)
			local redir = SpaceDamage(testSpace, damageRedirected)
			se:AddSafeDamage(redir)
			Board:AddEffect(se)

			missionData().proteccReloc = { mech:GetId(), pos.x, pos.y } --pleaseworkpleasework
			--mech:SetSpace(pos) --didn't work
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


local EVENT_onPawnDamaged = function(mission, pawn, damageTaken)
	if not isMission() or missionData().proteccReloc == nil or
			missionData().proteccReloc[1] == nil or
			missionData().proteccReloc[2] == nil or
			missionData().proteccReloc[3] == nil then
		return
	end

	local id = missionData().proteccReloc[1]
	local pos = Point(missionData().proteccReloc[2], missionData().proteccReloc[3])

	local pawn = Board:GetPawn(id)
	if pawn ~= nil then
		pawn:SetSpace(pos)
		--Board:AddAlert(pos, "Grid Protection")
	end

	--Clean data in any case
	missionData().proteccReloc = nil
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

truelch_DislocationMech = Pawn:new {
	Name = "Dislocation Mech",
	Class = "Ranged",
	Health = 2,
	MoveSpeed = 3,
	Image = "MechArt",
	ImageOffset = palette,
	SkillList = { "truelch_RiftInducer", --[["truelch_debug_weapon"]] },
	SoundLocation = "/enemy/burrower_2/",
	DefaultTeam = TEAM_PLAYER,
	ImpactMaterial = IMPACT_METAL,
	Massive = true,
}