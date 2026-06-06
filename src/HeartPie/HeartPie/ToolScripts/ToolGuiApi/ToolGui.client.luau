--!strict

-- Tool Gui


---------- Services ----------

local Players = game:GetService("Players")


---------- Imports ----------

local _ToolScripts = script.Parent.Parent
local Tooling = require(_ToolScripts:WaitForChild("Tooling"))

local _ToolUse = _ToolScripts:WaitForChild("ToolUse")
local ClientToolUseApi = require(_ToolUse:WaitForChild("ClientToolUseApi"))

local _ToolAssets = Tooling.tool:WaitForChild("ToolAssets")


---------- Constants ----------

local Constants = {}

Constants.apiBindableEvent = script.Parent:WaitForChild("ApiBindableEvent")

Constants.defaultPieToolScreen = _ToolAssets:WaitForChild("PieToolScreen")

Constants.pieTypeTexts = {
	["Server"] = [[<stroke color="#008F00"><font color="#00BF00">Server</font></stroke>]],
	["Client"] = [[<stroke color="#008F8F"><font color="#00BFBF">Client</font></stroke>]]
}

Constants.localPlayer = Players.LocalPlayer
Constants.playerGui = Constants.localPlayer.PlayerGui

do
	Constants.pieToolScreen = (function()
		local screenGui = Constants.playerGui:FindFirstChild("PieToolScreen") :: typeof(Constants.defaultPieToolScreen)
		if not screenGui then
			screenGui = Constants.defaultPieToolScreen:Clone()
			screenGui.Parent = Constants.playerGui
		end
		screenGui.Enabled = false
		return screenGui
	end)()

	Constants.pieTypeButton = Constants.pieToolScreen:WaitForChild("PieTypeButton")
	if not Constants.pieTypeButton:IsA("TextButton") then
		warn(`[Tool Gui]: Invalid pie type button found.`)
		return
	end
end

table.freeze(Constants)


---------- Globals ----------

local Globals = {}

Globals.pieTypeConnection = nil :: RBXScriptConnection?
Globals.pieTypeClickThrottle = false


---------- Local functions ----------

local updatePieTypeButton
local setPieType
local onSwitchPieType

local setUpPieToolScreen

local onEquipped
local onUnequipped


----- Pie type -----

updatePieTypeButton = function()
	-- Change the button's text
	if Tooling.configs.getIsClientPieType() then
		Constants.pieTypeButton.Text = "Pie Type: " .. Constants.pieTypeTexts.Client
	else
		Constants.pieTypeButton.Text = "Pie Type: " .. Constants.pieTypeTexts.Server
	end
end

setPieType = function(launchType: string)
	if launchType == "Client" or launchType == "Server" then
		ClientToolUseApi.setPieLaunchType(launchType)
		task.defer(function()
			updatePieTypeButton()
			task.delay(0.03, updatePieTypeButton)
		end)
	end
end

onSwitchPieType = function()
	if not Globals.pieTypeClickThrottle then
		Globals.pieTypeClickThrottle = true
		task.delay(0.2, function()
			Globals.pieTypeClickThrottle = false
		end)

		-- Check CanSwitchType
		if not Tooling.configs.getCanSwitchType() then
			return
		end

		-- Switch type
		if Tooling.configs.getIsClientPieType() then
			-- Change to server pie
			setPieType("Server")
		else
			-- Change to client pie
			setPieType("Client")
		end
	end
end


----- Set up -----

setUpPieToolScreen = function()
	-- Validate ShowGui
	if not Tooling.configs.getShowGui() then
		return
	end

	-- Enable gui
	Constants.pieToolScreen.Enabled = true

	-- Update button text
	task.defer(updatePieTypeButton)

	-- Create button clicked connection
	if Globals.pieTypeConnection then
		-- Disconnect if connection exists
		Globals.pieTypeConnection:Disconnect()
		Globals.pieTypeConnection = nil
	end
	task.delay(0.03, function()
		-- Check CanSwitchType
		if not Tooling.configs.getCanSwitchType() then
			return
		end

		-- Create connection
		Globals.pieTypeConnection = Constants.pieTypeButton.MouseButton1Click:Connect(onSwitchPieType)
	end)
end


----- Tool functions -----

onEquipped = function()
	setUpPieToolScreen()
end

onUnequipped = function()
	-- Disable gui
	Constants.pieToolScreen.Enabled = false

	-- Clean up connection
	if Globals.pieTypeConnection then
		Globals.pieTypeConnection:Disconnect()
		Globals.pieTypeConnection = nil
	end
end


----- Main -----

local function main()
	Constants.apiBindableEvent.Event:Connect(function(mode: string, ...)
		if mode == "Switch Pie Type" then
			onSwitchPieType()
		end
	end)
	Tooling.tool.Equipped:Connect(onEquipped)
	Tooling.tool.Unequipped:Connect(onUnequipped)
end


---------- Calling function ----------

main()
