--!strict
-- Pie Skins Checker Script

---------- Validate container ----------
-- Validate the script's container before running any code

-- For some server scripts
if not script:FindFirstAncestorWhichIsA("ServerScriptService") then
	return
end

---------- Services ----------

local ServerStorage = game:GetService("ServerStorage") or script.Parent.Parent.Parent.ServerStorage

local PieHikingServerStorage = ServerStorage:WaitForChild("PieHikingServerStorage")
if not PieHikingServerStorage then
	return
end

local Players = game:GetService("Players")

---------- Imports ----------

local PieSkinConditions = require(PieHikingServerStorage:WaitForChild("PieSkinConditions"))

---------- Instances ----------

local StoragePieSkins = PieHikingServerStorage:WaitForChild("PieSkins")

local PieHikingServerEvents = ServerStorage:WaitForChild("PieHikingServerEvents")
local ConditionalSkinsBindableEvent = PieHikingServerEvents:WaitForChild("ConditionalSkinsBindableEvent")

---------- Local functions ----------

local function getPlayerConditionalPieSkins(player: Player)
	local userId = player.UserId
	local conditionalPieSkins: {Instance} = {}

	-- Go through instances in the folder
	for _, pieSkin: Instance in StoragePieSkins:GetChildren() do
		-- Validate skin id
		local skinId = pieSkin:GetAttribute("SkinId")
		if not skinId then
			continue
		end

		-- Check condition
		local condition = PieSkinConditions[pieSkin.Name]
		if not (condition and condition(userId)) then
			continue
		end

		-- Add to result
		table.insert(conditionalPieSkins, pieSkin)
	end

	-- Return result
	return conditionalPieSkins
end

-- Add new skins to the pie tool, if the holder has them unlocked
local function populatePieSkins(pieTool: Tool)
	-- Get the skins folder
	local toolPieSkinsFolder = pieTool:WaitForChild("PieSkins", 0.1)
	if not toolPieSkinsFolder then
		return
	end

	-- Get player
	local character = pieTool.Parent
	local player = character and Players:GetPlayerFromCharacter(character)
	if not player then
		return
	end

	-- Get player's pie skins
	local conditionalPieSkins = getPlayerConditionalPieSkins(player)

	-- Go through tool's existing skins
	local isSkinAdded: {[string]: boolean} = {}
	for _, pieSkin: Instance in toolPieSkinsFolder:GetChildren() do
		isSkinAdded[pieSkin.Name] = true
	end

	-- Go through conditional pie skins
	local notAddedSkins: {Instance} = {}
	for _, pieSkin: Instance in conditionalPieSkins do
		if isSkinAdded[pieSkin.Name] then
			continue
		end
		table.insert(notAddedSkins, pieSkin)
		isSkinAdded[pieSkin.Name] = true
	end

	-- Clone the new pie skins to the tool, one by one
	for _, pieSkin in notAddedSkins do
		local newPieSkin = pieSkin:Clone()
		newPieSkin.Parent = toolPieSkinsFolder
	end
end

---------- Event functions ----------

local function onConditionalSkinsBindableEvent(mode: string, ...)
	if mode == "Populate Tool Skins" then
		populatePieSkins(...)
	end
end

---------- Calling / connectiong functions ----------

ConditionalSkinsBindableEvent.Event:Connect(onConditionalSkinsBindableEvent)
