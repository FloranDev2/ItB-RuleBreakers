-- This is heavily inspired by blockDeathByDeployment.lua by Lemonymous

local mod = mod_loader.mods[modApi.currentMod]
local path = mod.scriptPath
local functions = require(path.."functions")

local PHASE_DEPLOYMENT = 0

local function getDeploymentData(mission)
	return mission.deployment or {}
end

local function updateDeploymentListener(mission)
	local deployment = getDeploymentData(mission)

	if not deployment.in_progress then
		return
	end

	if deployment.phase == PHASE_DEPLOYMENT then
		local selectedPawnId = DetectDeployment:getSelected()

		if selectedPawnId == nil then
			return
		end		

		local selectedPawn = Board:GetPawn(selectedPawnId)

		if selectedPawn:GetType() == "truelch_GridMech" then
			--Display custom
			
			--Mark deploy positions that are NOT building with a cross
			for _, pos in ipairs(functions:missionData().deploy) do
				Board:MarkSpaceImage(pos, "combat/tile_icon/tile_cross.png", GL_Color(255, 150, 140, 1))
			end

			--Color in yellow buildings:
			--I think there's a method to get all buildings
			for j = 0, 7 do
				for i = 0, 7 do
					local curr = Point(i, j)
					if Board:IsBuilding(curr) then
						Board:MarkSpaceSimpleColor(curr, GL_Color(210, 180, 110, 0.75))
					end
				end
			end

			local mouseTile = mouseTile() --it is NOT a Point btw
			if mouseTile ~= nil then
				local newPos = Point(mouseTile.x, mouseTile.y)
				--LOG("newPos: "..newPos:GetString())
				if Board:IsBuilding(newPos) then
					selectedPawn:SetSpace(newPos)
				end
			end
		end
	end
end

--taken from lemon's blockDeathByDeployment and repurposed here
local function createClickBlocker(screen, uiRoot)
	local clickBlocker = Ui()
		:width(1):height(1)
		:setTranslucent()
		:addTo(uiRoot)

	function clickBlocker:mousedown(mx, my, button)
		local exitEarly = false
			or button ~= 1
			or DetectDeployment:isDeploymentPhase() == false

		if exitEarly then
			return false
		end

		local blockClick = false
		local selectedPawnId = DetectDeployment:getSelected()

		if selectedPawnId then
			local selectedPawn = Board:GetPawn(selectedPawnId)
			local hoveredPoint = Board:GetHighlighted()
			local hoveredPawn = Board:GetPawn(hoveredPoint)

			if selectedPawn:GetType() == "truelch_GridMech" then
				--Grid Mech is seleected. Can't swap with a tile that's not a building.
				if not Board:IsBuilding(hoveredPoint) then
					blockClick = true
				end

				--Unnecessary since regular Mechs won't be on a building tile?
				--[[
				if hoveredPawn ~= nil and hoveredPawn:GetType() ~= "truelch_GridMech" then
					blockClick = true
				end
				]]
			else
				--Regular pawn is selected. Can't swap if the other Mech is a Grid Mech.
				if hoveredPawn ~= nil and hoveredPawn:GetType() == "truelch_GridMech" then
					blockClick = true
				end
			end
		end

		--LOG("blockClick: "..tostring(blockClick))

		return blockClick
	end
end


local DEFAULT_DEPLOYMENT_ZONE = {}
for x = 1, 3 do
	for y = 1, 6 do
		table.insert(DEFAULT_DEPLOYMENT_ZONE, Point(x,y))
	end
end

local function isInsideDeployZone(point)
	local deploymentZone = extract_table(Board:GetZone("deployment"))
	if #deploymentZone == 0 then
		deploymentZone = DEFAULT_DEPLOYMENT_ZONE
	end

	for _, pos in ipairs(deploymentZone) do
		if pos == point then
			return true
		end
	end

	return false
end

local EVENT_onMissionStart = function(mission)
	--Let's just compute that once so that we don't have to do it again later
	functions:missionData().deploy = {} --unnecessary I think?
	for j = 0, 7 do
		for i = 0, 7 do
			local curr = Point(i, j)
			if not Board:IsBuilding(curr) and isInsideDeployZone(curr) then
				--LOG(" ---> curr: "..curr:GetString().." is inside deploy zone and NOT a building pos!")
				table.insert(functions:missionData().deploy, curr)
			end
		end
	end
end



modApi.events.onMissionUpdate:subscribe(updateDeploymentListener)
modApi.events.onMissionStart:subscribe(EVENT_onMissionStart)
--from block death, I need this to block Mechs swaps
modApi.events.onUiRootCreated:subscribe(createClickBlocker)