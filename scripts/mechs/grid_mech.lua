--------------------------
--- Imports and traits ---
--------------------------

local palette = modApi:getPaletteImageOffset("truelch_RuleBreakersMagenta")

local scriptPath = mod_loader.mods[modApi.currentMod].scriptPath
local trait = require(scriptPath.."/libs/trait") --unnecessary?
trait:add{
    pawnType = "truelch_GridMech",
    icon = "img/combat/icons/icon_grid_mech_trait.png",
    icon_offset = Point(0, 0),
    desc_title = "Grid Protector",
    desc_text = "Instead of moving, teleports to a building in move range.\nWhile the Grid Mech is alive, the building is immune to damage.\nThe Grid Mech is also immune to Web."
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
	SkillList = { "truelch_GridShield", "truelch_GridDischarge" },
	SoundLocation = "/enemy/bouncer_2/",
	DefaultTeam = TEAM_PLAYER,
	ImpactMaterial = IMPACT_METAL,
	Massive = true,
	Flying = true, --not really necessary in the end?
	IgnoreSmoke = true,
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


local function fooProtecc(se, effects)
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
                    se:AddScript(string.format([[Board:AddAlert(%s, "Grid Protection")]], spaceDamage.loc:GetString()))                                  
                    local testSpace = getProteccSpace()
                    local redir = SpaceDamage(testSpace, damageRedirected)
                    redir.sImageMark = "combat/icons/icon_resupply.png"
                    redir.bHide = true                   
                    se:AddScript(string.format("Board:GetPawn(%s):SetSpace(%s)", tostring(id), testSpace:GetString()))
                	se:AddSafeDamage(redir)
                    se:AddScript(string.format("Board:GetPawn(%s):SetSpace(%s)", tostring(id), origin:GetString()))
                end
            end
        end
    end
end

local function computeGridMechProtecc(p1, se)
	if se == nil then return end
	fooProtecc(se, se.effect)
	fooProtecc(se, se.q_effect)
end

local function computeGridMechProteccOld(--[[p1,]] se)
	--LOG("=================== computeGridMechProtecc ===================")
	if se == nil or se.effect == nil then return end

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

    --Queued effects
    --> It'll apply the damage to the Grid Mech instantly
    --for i = 1, se.q_effect:size() do
end

--TODO: add events for queued effects!



local function EVENT_onSkillBuild(mission, pawn, weaponId, p1, p2, skillEffect)
	if Game and weaponId ~= "Move" then
		LOG(string.format("onSkillBuild(weaponId: %s, p2: %s) -> turn: %s"
			weaponId, p2:GetString(), tostring(Game:GetTeamTurn())))
	end
	computeGridMechProtecc(skillEffect)
end
modapiext.events.onSkillBuild:subscribe(EVENT_onSkillBuild)

local function EVENT_onFinalEffectBuild(mission, pawn, weaponId, p1, p2, p3, skillEffect)
	--LOG("EVENT_onFinalEffectBuild(weaponId: "..weaponId..")")
	computeGridMechProtecc(skillEffect)
end
modapiext.events.onFinalEffectBuild:subscribe(EVENT_onFinalEffectBuild)

local function EVENT_onNextTurn(mission)
	LOG("========= EVENT_onNextTurn -> Currently it is turn of team: "..Game:GetTeamTurn())
end
modApi.events.onNextTurn:subscribe(EVENT_onNextTurn)



----- JUST SOME DEBUG

--local HOOK_onQueuedSkillStarted = function(mission, pawn, weaponId, p1, p2)
local EVENT_onQueuedSkillStarted = function(mission, pawn, weaponId, p1, p2)
	LOG(string.format("%s is using %s at %s!", pawn:GetMechName(), weaponId, p2:GetString()))
	if Board:IsBuilding(p2) then
		LOG(string.format("----------------> health: %s / max: %s", tostring(Board:GetHealth(p2), tostring(Board:GetMaxHealth(p2)))))
	end	
end
modapiext.events.onQueuedSkillStart:subscribe(EVENT_onQueuedSkillStarted)
--modapiext:addQueuedSkillStartHook(HOOK_onQueuedSkillStarted)


--local HOOK_onQueuedSkillEnded = function(mission, pawn, weaponId, p1, p2)
local EVENT_onQueuedSkillEnded = function(mission, pawn, weaponId, p1, p2)
	LOG(string.format("%s has finished using %s at %s!", pawn:GetMechName(), weaponId, p2:GetString()))
	if Board:IsBuilding(p2) then
		LOG(string.format("----------------> health: %s / max: %s", tostring(Board:GetHealth(p2), tostring(Board:GetMaxHealth(p2)))))
	end	
end
modapiext.events.onQueuedSkillEnd:subscribe(EVENT_onQueuedSkillEnded)
--modapiext:addQueuedSkillEndHook(HOOK_onQueuedSkillEnded)



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