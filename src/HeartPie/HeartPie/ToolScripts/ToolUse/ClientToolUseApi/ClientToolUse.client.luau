--!strict

-- Client Tool Use


---------- Services ----------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")


---------- Imports ----------

local _PieHiking_SharedStorage = ReplicatedStorage:WaitForChild("PieHiking_SharedStorage")
local _Modules = _PieHiking_SharedStorage:WaitForChild("Modules")
local BelovedRemote = require(_Modules:WaitForChild("BelovedRemote"))

local _ToolScripts = script.Parent.Parent.Parent
local _ToolVisual = _ToolScripts:WaitForChild("ToolVisual")
local ClientToolVisualApi = require(_ToolVisual:WaitForChild("ClientToolVisualApi"))

local _PieLaunch = _ToolScripts:WaitForChild("PieLaunch")
local ClientPieLaunchApi = require(_PieLaunch:WaitForChild("ClientPieLaunchApi"))

local Tooling = require(_ToolScripts:WaitForChild("Tooling"))


---------- Types ----------

type PieState = "Loaded" | "Launching" | "Unloaded" | "Reloading"


---------- Constants ----------

local Constants = {}

Constants.apiBindableEvent = script.Parent:WaitForChild("ApiBindableEvent")

Constants.localPlayer = Players.LocalPlayer

Constants.pieStateIconValues = {
	["Loaded"] = 0,
	["Unloaded"] = 0,
	["Reloading"] = 1,
	["Launching"] = 2,
}

table.freeze(Constants)


---------- Globals ----------

local Globals = {}

Globals.pieState = "Loaded" :: string

Globals.isLaunching = false


---------- Local functions ----------

local checkPlayerAlive

local setPieLaunchType

local getLaunchMotion
local firePie

local setPieState
local doPieLaunch
local doPieReload
local onPieLaunch
local autoReload


----- Player check -----

checkPlayerAlive = function(player: Player)
	local character = player and player.Character
	local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
	if not (humanoid and humanoid.Health > 0) then
		return false
	end
	return true
end


----- Pie type -----

setPieLaunchType = function(newLaunchType: "Client" | "Server")
	-- Sanity check for switching type
	if not Tooling.configs.getCanSwitchType() then
		return
	end

	-- Set pie launch type
	if newLaunchType == "Client" or newLaunchType == "Server" then
		local isClientPieType = (newLaunchType == "Client")
		Tooling.toolConfig:SetAttribute("IsClientPieType", isClientPieType)
		BelovedRemote.fire_toServer("Server Set Pie Launch Type", newLaunchType)
	end
end


----- Fire pie -----

getLaunchMotion = function(): {["CFrame"]: CFrame?, ["Direction"]: Vector3?}
	-- Get the mouse and handle position
	local player = Tooling.getOwner()
	local mouse = player and player:GetMouse()
	local mousePosition = mouse and mouse.Hit.Position
	local handlePosition = Tooling.handle.Position

	-- Compute the launch motion
	local launchCFrame = mousePosition and handlePosition and CFrame.new(handlePosition, mousePosition)
	local launchDirection = mousePosition and handlePosition and (mousePosition - Tooling.handle.Position).Unit
	local launchMotion = {
		["CFrame"] = launchCFrame,
		["Direction"] = launchDirection
	}
	return launchMotion
end

firePie = function()
	-- Get launch motion
	local launchMotion = getLaunchMotion()

	-- Launch Server or Client pies
	if Tooling.configs.getIsClientPieType() then
		ClientPieLaunchApi.launchClientPie(launchMotion)
	else
		BelovedRemote.fire_toServer("Launch Server Pie", launchMotion)
	end
end


----- Pie state -----

setPieState = function(state: PieState)
	if Constants.pieStateIconValues[state] and state ~= Globals.pieState then
		local oldState = Globals.pieState
		Globals.pieState = state

		-- Mouse icon
		Tooling.values.setMouseIconValue(Constants.pieStateIconValues[state])

		-- Model visibility
		if oldState == "Loaded" and state == "Launching" then
			ClientToolVisualApi.setPieTransparency(1)
		else
			local reloadShowPie = Tooling.configs.getReloadShowPie()
			local willShowPie = (
				(reloadShowPie and oldState == "Unloaded" and state == "Reloading")
				or (not reloadShowPie and oldState == "Reloading" and state == "Loaded")
			)
			if willShowPie then
				ClientToolVisualApi.setPieTransparency(nil)
			end
		end
	end
end

doPieLaunch = function()
	-- Launch
	setPieState("Launching")
	task.defer(firePie)

	-- Unload
	task.delay(Tooling.configs.getDurationThrow(), function()
		setPieState("Unloaded")
		Globals.isLaunching = false
	end)
end

doPieReload = function()
	-- Reload
	setPieState("Reloading")
	task.delay(Tooling.configs.getDurationReload(), function()
		setPieState("Loaded")
		Globals.isLaunching = false
	end)
end

onPieLaunch = function()
	if checkPlayerAlive(Constants.localPlayer) and not Globals.isLaunching then
		-- Launch or reload pie
		Globals.isLaunching = true
		if Globals.pieState == "Loaded" then
			-- Launch
			doPieLaunch()

			-- Auto reload
			if Tooling.configs.getAutoReload() then
				autoReload()
			end
		elseif Globals.pieState == "Unloaded" then
			-- Reload
			doPieReload()
		end
	end
end

autoReload = function()
	while true do
		if Globals.pieState == "Unloaded" or Globals.pieState == "Reloading" then
			break
		end
		task.wait()
	end
	if Globals.pieState == "Unloaded" then
		doPieReload()
	end
end


----- Main -----

local function main()
	Constants.apiBindableEvent.Event:Connect(function(mode: string, ...)
		if mode == "Launch Pie" then
			onPieLaunch()
		elseif mode == "Set Pie Launch Type" then
			setPieLaunchType(...)
		end
	end)
end


---------- Calling function ----------

main()
