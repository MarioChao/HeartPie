--!strict
-- Server Pie Handler Script

---------- Services ----------

local Players = game:GetService("Players")

---------- Instances ----------

local Tool = script.Parent.Parent.Parent
local ToolEvents = Tool:WaitForChild("ToolEvents")
local PieTypeRemoteEvent = ToolEvents:WaitForChild("PieTypeRemoteEvent")

---------- Variables ----------

local character: Model? = nil
local player: Player? = nil

---------- Local unctions ----------

local function setPieLaunchType(caller: Player, newLaunchType: string)
	-- Sanity check for switching type
	local canSwitchType = Tool:GetAttribute("CanSwitchType")
	if not canSwitchType then
		return
	end

	-- Validate player
	if caller ~= player then
		return
	end

	-- Set pie launch type
	if newLaunchType == "Client" or newLaunchType == "Server" then
		local isClientPieType = (newLaunchType == "Client")
		Tool:SetAttribute("IsClientPieType", isClientPieType)
	end
end

local function onToolEquipped()
	character = Tool.Parent
	player = character and Players:GetPlayerFromCharacter(character)
end

local function onToolUnequipped()
	character = nil
	player = nil
end

---------- Event functions ----------

local function onPieTypeServerEvent(caller: Player, mode: string, ...)
	if mode == "Set Pie Type" then
		setPieLaunchType(caller, ...)
	end
end

---------- Calling / connecting functions ----------

Tool.Equipped:Connect(onToolEquipped)
Tool.Unequipped:Connect(onToolUnequipped)
PieTypeRemoteEvent.OnServerEvent:Connect(onPieTypeServerEvent)
