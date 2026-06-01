--!strict

-- Server Pie Ammo Launcher


---------- Validate container ----------

-- Server script service
if not script:FindFirstAncestorWhichIsA("ServerScriptService") then
	return
end


---------- Services ----------

local ReplicatedStorage = game:GetService("ReplicatedStorage")


---------- Imports ----------

local _PieHiking_SharedStorage = ReplicatedStorage:WaitForChild("PieHiking_SharedStorage")
local _AmmoModules = _PieHiking_SharedStorage:WaitForChild("AmmoModules")
local RegularPieAmmo = require(_AmmoModules:WaitForChild("RegularPieAmmo"))


---------- Constants ----------

local Constants = {}

Constants.apiBindableEvent = script.Parent:WaitForChild("ApiBindableEvent")

table.freeze(Constants)


---------- Local functions ----------

local onCreateAndLaunch


----- Launch pie -----

onCreateAndLaunch = function(ammoModel: Model, player: Player)
	if not ammoModel:IsA("Model") then
		return
	end
	local ammo = RegularPieAmmo.new(ammoModel, true)
	ammo:setupAmmo()
	local character = player.Character
	if character then
		ammo:disablePieCollideCharacter(character)
	else
		print(`[Server Pie Ammo Launcher]: Unable to disable collision for player '{player}'.`)
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
