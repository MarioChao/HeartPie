--!strict
-- Tool Use Script

---------- Services ----------

local Players = game:GetService("Players")

---------- Instances ----------

local Tool = script.Parent.Parent.Parent

local ToolEvents = Tool:WaitForChild("ToolEvents")
local ActionsBindable = ToolEvents:WaitForChild("ActionsBindable")

local PieTypeEvent = ToolEvents:WaitForChild("PieTypeEvent")

local ToolAssets = Tool:WaitForChild("ToolAssets")
local DefaultPieToolScreen = ToolAssets:WaitForChild("PieToolScreen")

---------- Variables ----------

local pieTypeTexts = {
	["Server"] = [[<stroke color="#008F00"><font color="#00BF00">Server</font></stroke>]],
	["Client"] = [[<stroke color="#008F8F"><font color="#00BFBF">Client</font></stroke>]]
}

local playerGui: PlayerGui = nil
local pieToolScreen: ScreenGui? = nil
local pieTypeButton: TextButton? = nil
local pieTypeConnection: RBXScriptConnection? = nil

local pieTypeClickThrottle = false

---------- Local functions ----------

local function updatePieTypeButton()
	-- Validate button
	if not (pieTypeButton and pieTypeButton:IsA("TextButton")) then
		return
	end

	-- Change the button's text
	local isClientPieType = Tool:GetAttribute("IsClientPieType")
	if isClientPieType then
		pieTypeButton.Text = "Pie Type: " .. pieTypeTexts.Client
	else
		pieTypeButton.Text = "Pie Type: " .. pieTypeTexts.Server
	end
end

local function setPieType(launchType: string)
	if launchType == "Client" or launchType == "Server" then
		PieTypeEvent:Fire("Set Pie Type", launchType)
		task.defer(function()
			updatePieTypeButton()
			task.delay(0.03, updatePieTypeButton)
		end)
	end
end

local function onSwitchPieType()
	if not pieTypeClickThrottle then
		pieTypeClickThrottle = true
		task.delay(0.2, function()
			pieTypeClickThrottle = false
		end)

		-- Check CanSwitchType
		local canSwitchType = Tool:GetAttribute("CanSwitchType")
		if not canSwitchType then
			return
		end

		-- Switch type
		local isClientPieType = Tool:GetAttribute("IsClientPieType")
		if isClientPieType then
			-- Change to server pie
			setPieType("Server")
		else
			-- Change to client pie
			setPieType("Client")
		end
	end
end

local function getPieToolScreen()
	local screenGui = playerGui:FindFirstChild("PieToolScreen")
	if not screenGui then
		screenGui = DefaultPieToolScreen:Clone()
		screenGui.Parent = playerGui
	end
	return screenGui
end

local function setupPieToolScreen()
	-- Validate ShowGui
	if not Tool:GetAttribute("ShowGui") then
		return
	end

	-- Get tool screen
	pieToolScreen = getPieToolScreen()

	-- Get gui instances
	task.desynchronize()
	pieTypeButton = pieToolScreen and pieToolScreen:FindFirstChild("PieTypeButton") :: TextButton
	if not (pieToolScreen and pieTypeButton and pieTypeButton:IsA("TextButton")) then
		return
	end

	-- Enable gui
	task.synchronize()
	pieToolScreen.Enabled = true

	-- Update button text
	task.defer(updatePieTypeButton)

	-- Create button clicked connection
	if pieTypeConnection then
		-- Disconnect if connection exists
		pieTypeConnection:Disconnect()
		pieTypeConnection = nil
	end
	task.delay(0.03, function()
		-- Check CanSwitchType
		local canSwitchType = Tool:GetAttribute("CanSwitchType")
		if not canSwitchType then
			return
		end

		-- Check button
		if not pieTypeButton then
			return
		end

		-- Create connection
		pieTypeConnection = pieTypeButton.MouseButton1Click:Connect(onSwitchPieType)
	end)
end

---------- Tool functions ----------

local function onEquipped()
	playerGui = Players.LocalPlayer:WaitForChild("PlayerGui", 5)
	if playerGui then
		setupPieToolScreen()
	end
end

local function onUnequipped()
	-- Disable gui and reset variables
	if pieToolScreen then
		pieToolScreen.Enabled = false
		pieToolScreen = nil
		pieTypeButton = nil
	end

	-- Cleanup connection
	if pieTypeConnection then
		pieTypeConnection:Disconnect()
		pieTypeConnection = nil
	end
end

---------- Event functions ----------

local function onActionsEvent(mode: string, ...)
	-- Validate equipped
	if not Tool.Equipped then
		return
	end

	-- Actions
	if mode == "Switch Pie Type" then
		onSwitchPieType()
	end
end

---------- Calling / connecting functions ----------

ActionsBindable.Event:Connect(onActionsEvent)
Tool.Equipped:Connect(onEquipped)
Tool.Unequipped:Connect(onUnequipped)
