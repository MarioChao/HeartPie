--!strict
-- Server Pie Ammo Script

---------- Validate container ----------
-- Validate the script's container before running any code

-- Not under a tool
if script:FindFirstAncestorWhichIsA("Tool") then
	return
end

-- Server scripts
if not script:FindFirstAncestorWhichIsA("ServerScriptService") then
	return
end

---------- Services ----------

local ReplicatedStorage = game:GetService("ReplicatedStorage")

---------- Imports ----------

local _PieHikingSharedStorage = ReplicatedStorage:WaitForChild("PieHikingSharedStorage")
local _AmmoModules = _PieHikingSharedStorage:WaitForChild("AmmoModules")
local PieAmmo = require(_AmmoModules:WaitForChild("RegularPieAmmo"))

---------- Variables ----------

local _PieHikingEvents = _PieHikingSharedStorage:WaitForChild("PieHikingEvents")
local PieHikeBindable = _PieHikingEvents:WaitForChild("PieHikeBindable")

---------- Local functions ----------

local function newAmmo(ammoModel: Model, player: Player)
	if not ammoModel:IsA("Model") then
		return
	end
	local ammo = PieAmmo.new(ammoModel, true)
	ammo:setupAmmo()
	ammo:disablePieCollideCharacter(player.Character)
	ammo:launchPie()
end

---------- Event functions ----------

local function onPieHikeBindableEvent(mode: string, ...)
	--[[ Always launched from server ]]
	if mode == "Start Launch" then
		newAmmo(...)
	end
end

---------- Calling / connecting functions ----------

PieHikeBindable.Event:Connect(onPieHikeBindableEvent)
