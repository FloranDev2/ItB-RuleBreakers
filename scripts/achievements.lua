local mod = modApi:getCurrentMod()
local squad = "truelch_MechDivers"

--CONSTANTS
local GRID_PROTECC_GOAL = 10
local SAW_DMG_GOAL = 10

--[[
Ideas:
Grid Mech
- Power overwhelming: Deal 7 damage with the Grid Discharge
- Last resort / Sparkle of hope: Deal 1 damage with the Grid Discharge
- The Grid Mech dies but does not surrender! Have a Grid Mech die on a Building / take X damage for a building (during a mission / game / island?)

Sawblade Mech
- Deal X damage after one use of the Sawblade Launcher (no matter the way it's used)

Dislocation Mech
]]

--ADD ACHIEVEMENTS
local achievements = {
	truelch_PowerOverwhelming = modApi.achievements:add{
		id = "truelch_PowerOverwhelming",
		name = "Power overwhelming!",
		tooltip = "Deal at least 7 damage with the Grid Discharge.",
		image = mod.resourcePath.."img/achievements/truelch_PowerOverwhelming.png",
		squad = squad,
	},
	--[[
	truelch_LastResort = modApi.achievements:add{
		id = "truelch_LastResort",
		name = "Last Resort",
		tooltip = "Deal 1 damage with the Grid Discharge.",
		image = mod.resourcePath.."img/achievements/truelch_LastResort.png",
		squad = squad,
	},
	]]
	truelch_GridProtecc = modApi.achievements:add{
		id = "truelch_GridProtecc",
		name = "The Grid Mech dies but does not surrender!",
		--tooltip = "Have a Grid Mech die on a Building.",
		tooltip = "Make the Grid Mech take "..tostring(GRID_PROTECC_GOAL).." damage instead of a Building.",
		image = mod.resourcePath.."img/achievements/truelch_GridProtecc.png",
		squad = squad,
	}
	truelch_SawDamage = modApi.achievements:add{
		id = "truelch_SawDamage",
		name = "SAW",
		tooltip = "Deal "..tostring(SAW_DMG_GOAL).." in one use of the Sawblade Launcher.",
		image = mod.resourcePath.."img/achievements/truelch_SawDamage.png",
		squad = squad,
	}
}

--- HELPER FUNCTIONS ---
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

local function isMissionBoard()
	return true
		and isMission()
		and Board ~= nil
		and Board:IsTipImage() == false
end

local function isSquad()
	return true
		and isGame()
		and GAME.additionalSquadData.squad == squad
end

--- COMPLETE ACHIEVEMENT ---

--[[
truelch_PowerOverwhelming
truelch_LastResort
truelch_GridProtecc
truelch_SawDamage
]]

function truelch_completePowerOverwhelming(isDebug)
	if isDebug then
		LOG("truelch_completePowerOverwhelming()")
		Board:AddAlert(Point(4, 4), "Power overwhelming completed!")
	else
		if not achievements.truelch_PowerOverwhelming:isComplete() then
			achievements.truelch_PowerOverwhelming:addProgress{ complete = true }
		end
	end
end

function truelch_completeLastResort(isDebug)
	if isDebug then
		LOG("truelch_completeLastResort()")
		Board:AddAlert(Point(4, 4), "Last Resort completed!")
	else
		if not achievements.truelch_LastResort:isComplete() then
			achievements.truelch_LastResort:addProgress{ complete = true }
		end
	end
end

function truelch_completeGridProtecc(isDebug)
	if isDebug then
		LOG("truelch_completeLastResort()")
		Board:AddAlert(Point(4, 4), "The Grid Mech dies but does not surrender!")
	else
		if not achievements.truelch_GridProtecc:isComplete() then
			achievements.truelch_GridProtecc:addProgress{ complete = true }
		end
	end
end

function truelch_completeSawDamage(isDebug)
	if isDebug then
		LOG("truelch_completeSawDamage()")
		Board:AddAlert(Point(4, 4), "Saw Damage completed!")
	else
		if not achievements.truelch_SawDamage:isComplete() then
			achievements.truelch_SawDamage:addProgress{ complete = true }
		end
	end
end

--- DATA ---
local function missionData(msg)
    local mission = GetCurrentMission()

    if mission == nil then
    	LOG("missionData -> mission == nil -> msg: "..msg)
    end

    if mission.truelch_RuleBreakers == nil then
        mission.truelch_RuleBreakers = {}
    end

    return mission.truelch_RuleBreakers
end

local function gameData()
	if GAME.truelch_RuleBreakers == nil then
		GAME.truelch_RuleBreakers = {}
	end

	if GAME.truelch_RuleBreakers.achievementData == nil then
		GAME.truelch_RuleBreakers.achievementData = {}
	end

	return GAME.truelch_RuleBreakers.achievementData --redundant?
end

local function achievementData()
	--using mission will cause an error on island menu while looking in achievements tooltips
	local game = gameData()  --redundant?

	if game.truelch_RuleBreakers == nil then
		game.truelch_RuleBreakers = {}
	end

	--Return
	return game.truelch_RuleBreakers.achievementData
end


--- TOOLTIP ---
local getTooltip = achievements.truelch_GridProtecc.getTooltip
achievements.truelch_GridProtecc.getTooltip = function(self)
	local result = getTooltip(self)

	local status = ""

	if isMission() and not comple then
		status = status.."\nHas Mech respawned this mission? "..tostring(missionData("getTooltip").isRespawnUsed)
		status = status.."\nIs this achievement still doable? "..tostring(achievementData().isRespawnAchvStillOk)
	end

	result = result..status

	return result
end

local getTooltip = achievements.truelch_KillRobots.getTooltip
achievements.truelch_KillRobots.getTooltip = function(self)
	local result = getTooltip(self)

	local status = ""

	if isGame() and not achievements.truelch_KillRobots:isComplete() then
		status = "\nBots democratized: "..tostring(achievementData().botsKilled.." / "..tostring(ROBOTS_KILL_GOAL))
	end

	result = result..status

	return result
end