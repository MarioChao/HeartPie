--!strict
-- Pie Handler Script

-- Tool info
local Tool = script.Parent.Parent.Parent
local ToolEvents = Tool:WaitForChild("ToolEvents")
local PieTypeEvent = ToolEvents:WaitForChild("PieTypeEvent")
local PieTypeRemoteEvent = ToolEvents:WaitForChild("PieTypeRemoteEvent")
local PieLaunchEvent = ToolEvents:WaitForChild("PieLaunchEvent")
local PieLaunchRemoteEvent = ToolEvents:WaitForChild("PieLaunchRemoteEvent")
local ToolVisualEvent = ToolEvents:WaitForChild("ToolVisualEvent")
local ToolVisualRemoteEvent = ToolEvents:WaitForChild("ToolVisualRemoteEvent")

local ToolValues = Tool:WaitForChild("ToolValues")
local Icon = ToolValues:WaitForChild("Icon")

local PieModel = Tool:WaitForChild("PieModel")

local Handle = Tool:WaitForChild("Handle")

-- Services
local Players = game:GetService("Players")

-- Variables
local throwSeconds = 0.6
local reloadSeconds = 0.5

local isClientPieType = Tool:GetAttribute("IsClientPieType")
local launchType = (isClientPieType and "Client") or "Server"
local pieState = "Loaded"
local pieStateIconValues = {
	["Loaded"] = 0,
	["Unloaded"] = 0,
	["Reloading"] = 1,
	["Launching"] = 2,
}

local character: Model? = nil
local humanoid: Humanoid? = nil
local player: Player? = nil

-- Functions
local function checkPlayerAlive()
	-- Check whether the variables refer to an alive player
	if not (character and character.Parent) then
		return false
	end
	if not (humanoid and humanoid.Parent and humanoid.Health > 0) then
		return false
	end
	if not (player and player.Parent) then
		return false
	end
	return true
end

local function setPieLaunchType(newLaunchType: string)
	-- Sanity check for switching type
	local canSwitchType = Tool:GetAttribute("CanSwitchType")
	if not canSwitchType then
		return
	end
	
	-- Set pie launch type
	if newLaunchType == "Client" or newLaunchType == "Server" then
		local isClientPieType = (newLaunchType == "Client")
		Tool:SetAttribute("IsClientPieType", isClientPieType)
		PieTypeRemoteEvent:FireServer("Set Pie Type", newLaunchType)
		launchType = newLaunchType
	end
end

local function getLaunchMotion(): {["CFrame"]: CFrame?, ["Direction"]: Vector3?}
	-- Get the mouse and handle position
	local mouse = player and player:GetMouse()
	local mousePosition = mouse and mouse.Hit.Position
	local handlePosition = Handle.Position
	
	-- Compute the launch motion
	local launchCFrame = mousePosition and handlePosition and CFrame.new(handlePosition, mousePosition)
	local launchDirection = mousePosition and handlePosition and (mousePosition - Handle.Position).Unit
	local launchMotion = {
		["CFrame"] = launchCFrame,
		["Direction"] = launchDirection
	}
	return launchMotion
end

local function firePie()
	-- Get launch motion
	local launchMotion = getLaunchMotion()
	
	-- Launch Server or Client pies
	if launchType == "Client" then
		PieLaunchEvent:Fire("Launch Pie", launchMotion)
	elseif launchType == "Server" then
		PieLaunchRemoteEvent:FireServer("Launch Pie", launchMotion)
	end
end

local function setPieState(state: string)
	if pieStateIconValues[state] and state ~= pieState then
		local oldState = pieState
		pieState = state
		
		-- Mouse icon
		Icon.Value = pieStateIconValues[state]
		
		-- Model visibility
		if oldState == "Unloaded" and pieState == "Reloading" then
			ToolVisualEvent:Fire("Set Pie Transparency", nil)
		elseif oldState == "Loaded" and pieState == "Launching" then
			ToolVisualEvent:Fire("Set Pie Transparency", 1)
		end
	end 
end

-- Tool functions
local function onToolEquipped()
	character = Tool.Parent
	humanoid = character and character:FindFirstChildOfClass("Humanoid")
	player = character and Players:GetPlayerFromCharacter(character)
end

local function onToolUnequipped()
	character = nil
	humanoid = nil
	player = nil
end

local function onToolActivated()
	if checkPlayerAlive() and Tool.Enabled then
		-- Launch or reload pie
		Tool.Enabled = false
		if pieState == "Loaded" then
			-- Launch
			setPieState("Launching")
			task.defer(firePie)
			
			-- Unload
			task.delay(throwSeconds, function()
				setPieState("Unloaded")
				Tool.Enabled = true
			end)
		elseif pieState == "Unloaded" then
			-- Reload
			setPieState("Reloading")
			task.delay(reloadSeconds, function()
				setPieState("Loaded")
				Tool.Enabled = true
			end)
		end
	end
end

-- Event functions
local function onPieTypeEvent(mode: string, ...)
	if mode == "Set Pie Type" then
		setPieLaunchType(...)
	end
end

-- Calling / connecting functions
PieTypeEvent.Event:Connect(onPieTypeEvent)
Tool.Equipped:Connect(onToolEquipped)
Tool.Unequipped:Connect(onToolUnequipped)
Tool.Activated:Connect(onToolActivated)
