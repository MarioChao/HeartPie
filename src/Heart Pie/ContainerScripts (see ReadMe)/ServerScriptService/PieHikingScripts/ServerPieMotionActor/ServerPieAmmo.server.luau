--!strict
-- Server Pie Ammo Script

---------- Validate container ----------
-- Validate the script's container before running any code

-- For some server scripts
if not script:FindFirstAncestorWhichIsA("ServerScriptService") then
	return
end

---------- Services ----------

local ReplicatedStorage = game:GetService("ReplicatedStorage")

---------- Imports ----------

local PieHikingModules = ReplicatedStorage:WaitForChild("PieHikingModules")
local PieAmmo = require(PieHikingModules:WaitForChild("RegularPieAmmoModule"))

---------- Variables ----------

local PieHikingEvents = ReplicatedStorage:WaitForChild("PieHikingEvents") :: Folder
local PieHikeBindable = PieHikingEvents:WaitForChild("PieHikeBindable") :: BindableEvent

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
