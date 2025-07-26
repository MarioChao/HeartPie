--!strict
-- Client Pie Ammo Script

---------- Validate container ----------
-- Validate the script's container before running any code

-- For certain client scripts
if not script:FindFirstAncestorWhichIsA("PlayerScripts") then
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
	local ammo = PieAmmo.new(ammoModel, false)
	ammo:setupAmmo()
	if not ammoModel:GetAttribute("_CanCollideThrower") then
		ammo:disablePieCollideCharacter(player.Character)
	end
	ammo:launchPie()
end

---------- Event functions ----------

local function onPieHikeBindableEvent(mode: string, ...)
	--[[ Always launched from client ]]
	if mode == "Start Launch" then
		newAmmo(...)
	end
end

---------- Calling / connecting functions ----------

PieHikeBindable.Event:Connect(onPieHikeBindableEvent)
