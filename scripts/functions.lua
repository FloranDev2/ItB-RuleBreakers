---------------
--- IMPORTS ---
---------------

local mod = mod_loader.mods[modApi.currentMod]
local this = {}


---------------------------
--- GAME / MISSION DATA ---
---------------------------

function this:isGame()
    return true
        and Game ~= nil
        and GAME ~= nil
end

function this:isMission()
	local mission = GetCurrentMission()

	return true
		and this:isGame()
		and mission ~= nil
		and mission ~= Mission_Test
end

function this:missionData()
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
	if mission.truelch_RuleBreakers.sawAmount == nil then
		mission.truelch_RuleBreakers.sawAmount = {}
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


---------------
--- UTILITY ---
---------------

function this:isVarNil(msg, var)
	if var == nil then
		LOG("----------- "..msg.." is nil :(")
	else
		LOG("----------- "..msg.." exists :)")
	end
end


----------------
--- SAWBLADE ---
----------------

function this:isEquippedWithSawbladeLauncher(mech)
	local ret = mech ~= nil and (mech:IsWeaponPowered("truelch_SawbladeLauncher_A") or
		mech:IsWeaponPowered("truelch_SawbladeLauncher_A") or
		mech:IsWeaponPowered("truelch_SawbladeLauncher_B") or
		mech:IsWeaponPowered("truelch_SawbladeLauncher_AB"))

	LOG("isEquippedWithSawbladeLauncher -> mech: "..mech:GetMechName().." -> ret: "..tostring(ret))

	return ret
end

function this:isSawbladePos(pos)
	local pawn = Board:GetPawn(pos)
	return pawn ~= nil and pawn:GetType() == "truelch_Sawblade"
end

function this:isReinforcedSawbladePos(point)
	local pawn = Board:GetPawn(point)
	return pawn ~= nil and pawn:GetType() == "truelch_Sawblade_A"
end

function this:setSawblade(pawn, newValue)
	LOG("setSawblade()")
	if pawn == nil or not this:isEquippedWithSawbladeLauncher(pawn) then
		LOG(" -> return!")
		return
	end

	LOG(" -> ok!")

	local pawnId = pawn:GetId()

	if this:missionData().sawAmount[pawnId] == nil then
		this:missionData().sawAmount[pawnId] = 0
	end
	local oldValue = this:missionData().sawAmount[pawnId]

	--Limits
	if newValue < 0 then
		newValue = 0
	elseif newValue > 1 then
		newValue = 1
	end

	--Find what type of sawblade launcher it is
	local weapons = pawn:GetPoweredWeapons()
	local sawbladeLauncher = nil
	for i = 1, 2 do --weapons index
		local weapon = weapons[i]
		if type(weapon) == 'table' then weapon = weapon.__Id end
		if string.find(weapon, "truelch_SawbladeLauncher") ~= nil then
			sawbladeLauncher = weapon
		end
	end

	if sawbladeLauncher == nil then --shouldn't happen since we checked earlier isEquippedWithSawbladeLauncher(pawn)
		LOG("--------- WTF -> sawbladeLauncher == nil")
		return
	end

	--Update anims
	local anim = "truelch_anim_sawblade" --truelch_anim_sawblade_A
	if sawbladeLauncher ~= nil and sawbladeLauncher.Anim ~= nil then		
		--anim = sawbladeLauncher.Anim   --this?
		anim = _G[sawbladeLauncher].Anim --or this?
		LOG("----------- it worked! anim: "..anim)
	end

	if oldValue == 0 and newValue == 1 then
		LOG("------------> customAnim:add")
		customAnim:add(pawnId, weapon)
	elseif oldValue == 1 and newValue == 0 then
		LOG("------------> customAnim:rem")
		customAnim:rem(pawnId, weapon)
	end

	--Apply value
	this:missionData().sawAmount[pawn:GetId()] = newValue
end

function this:addSawblade(pawn, incr)
	LOG("addSawblade()")
	if pawn == nil then
		LOG(" -> pawn is nil!")
		return
	end
	LOG(" -> addSawblade(pawn: "..pawn:GetMechName()..", incr: "..tostring(incr)..")")

	--local oldValue = this:missionData().sawAmount[pawn:GetId()]
	local oldValue = this:getSawbladeAmount(pawn)
	local newValue = oldValue + incr

	--Limits
	if newValue < 0 then
		newValue = 0
	elseif newValue > 1 then
		newValue = 1
	end

	--Apply value
	this:setSawblade(pawn, newValue)
end

--Return -1 if no sawblade launcher is equipped?
--or nil?
function this:getSawbladeAmount(pawn)
	LOG("getSawbladeAmount()")
	if pawn == nil then
		LOG(" -> return")
		return
	end

	LOG(" -> ok")

	local pawnId = pawn:GetId()

	local cond1 = this:isEquippedWithSawbladeLauncher(pawn)
	local cond2 = this:missionData().sawAmount[pawnId] == nil

	LOGF("cond1: %s, cond2: %s", tostring(cond1), tostring(cond2))

	if cond2 and cond2 then
		--this:setSawblade(pawn, 0)
		this:missionData().sawAmount[pawnId] = 0
		LOG(" -> init sawAmount")
	end

	return this:missionData().sawAmount[pawnId]
end


--------------
--- RETURN ---
--------------

return this