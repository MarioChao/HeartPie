--!strict
-- Client Pie Ammo Script

---------- Validate container ----------
-- Validate the script's container before running any code

-- For certain client scripts
if not script:FindFirstAncestorWhichIsA("PlayerScripts") then
	return
end

-- Ammo info
local PieMotionActor = script.Parent
local PieAmmo = require(PieMotionActor:WaitForChild("PieAmmoModule"))

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Variables
local PieHikingEvents = ReplicatedStorage:WaitForChild("PieHikingEvents") :: Folder
local PieHikeEvent = PieHikingEvents:WaitForChild("PieHikeEvent") :: BindableEvent
--local PieHikeRemoteEvent = PieHikingEvents:WaitForChild("PieHikeRemoteEvent") :: RemoteEvent

-- Functions
local function newAmmo(ammoModel: Model)
	if not ammoModel:IsA("Model") then
		return
	end
	local ammo = PieAmmo.new(ammoModel, false)
	ammo:setupAmmo()
	ammo:launchPie()
end

-- Event functions
local function onPieHikeEvent(mode: string, ...)
	--[[ Always launched from client ]]
	if mode == "Start Launch" then
		newAmmo(...)
	end
end

-- Calling / connecting functions
PieHikeEvent.Event:Connect(onPieHikeEvent)
