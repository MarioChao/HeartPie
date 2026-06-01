--!strict

-- Client Pie Ammo Launcher


---------- Validate container ----------

-- Replicated storage
if not script:FindFirstAncestorWhichIsA("ReplicatedStorage") then
	return
end


---------- Services ----------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")


---------- Imports ----------

local _PieHiking_SharedStorage = ReplicatedStorage:WaitForChild("PieHiking_SharedStorage")
local _AmmoModules = _PieHiking_SharedStorage:WaitForChild("AmmoModules")
local RegularPieAmmo = require(_AmmoModules:WaitForChild("RegularPieAmmo"))


---------- Constants ----------

local Constants = {}

Constants.apiBindableEvent = script.Parent:WaitForChild("ApiBindableEvent")

Constants.localPlayer = Players.LocalPlayer

table.freeze(Constants)


---------- Local functions ----------

local onCreateAndLaunch


----- Launch pie -----

onCreateAndLaunch = function(ammoModel: Model)
	if not ammoModel:IsA("Model") then
		return
	end
	local ammo = RegularPieAmmo.new(ammoModel, false)
	ammo:setupAmmo()
	if not ammoModel:GetAttribute("_CanCollideThrower") then
		local character = Constants.localPlayer.Character
		if character then
			ammo:disablePieCollideCharacter(character)
		else
			print(`[Client Pie Ammo Launcher]: Unable to disable collision.`)
		end
	end
	ammo:launchPie()
end


----- Main -----

local function main()
	Constants.apiBindableEvent.Event:Connect(function(mode: string, ...)
		if mode == "Create and Launch" then
			onCreateAndLaunch(...)
		end
	end)
end


---------- Calling function ----------

main()
