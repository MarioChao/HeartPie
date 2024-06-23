--!strict
-- Client Setup Check Script

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local StarterPlayer = game:GetService("StarterPlayer")

-- Functions
local function checkForChild(parent: Instance, childName: string): Instance
	local child = parent:WaitForChild(childName, 5)
	if not child then
		warn("Child " .. childName .. " not found in " .. tostring(parent))
	end
	assert(child)
	return child
end

local function checkScriptEnabled(checkScript: Script)
	if not checkScript.Enabled then
		warn("Script " .. tostring(checkScript) .. " not enabled")
	end
	assert(checkScript.Enabled)
end

local function checkReplicatedStorage()
	local PieHikingEvents = checkForChild(ReplicatedStorage, "PieHikingEvents")
	local CSCPieRemoteEvent = checkForChild(PieHikingEvents, "CSCPieRemoteEvent")
	local PieHikeEvent = checkForChild(PieHikingEvents, "PieHikeEvent")
	local PieHikeRemoteEvent = checkForChild(PieHikingEvents, "PieHikeRemoteEvent")
end

local function checkStarterGui()
	local PieToolScreen = checkForChild(StarterGui, "PieToolScreen")
	local PieTypeButton = checkForChild(PieToolScreen, "PieTypeButton")
end

local function checkStarterPlayer()
	local StarterPlayerScripts = checkForChild(StarterPlayer, "StarterPlayerScripts")
	local PieHikingPlayerScripts = checkForChild(StarterPlayerScripts, "PieHikingPlayerScripts")
	local CSCPieMotionActor = checkForChild(PieHikingPlayerScripts, "CSCPieMotionActor")
	local CSCPieAmmo = checkForChild(CSCPieMotionActor, "CSCPieAmmo") :: Script
	local CSCPieAmmoModule = checkForChild(CSCPieMotionActor, "CSCPieAmmoModule")
	local PieMotionActor = checkForChild(PieHikingPlayerScripts, "PieMotionActor")
	local ClientPieAmmo = checkForChild(PieMotionActor, "ClientPieAmmo") :: Script
	local ServerPieAmmo = checkForChild(PieMotionActor, "ServerPieAmmo") :: Script
	local PieAmmoModule = checkForChild(PieMotionActor, "PieAmmoModule")
	checkScriptEnabled(CSCPieAmmo)
	checkScriptEnabled(ClientPieAmmo)
	checkScriptEnabled(ServerPieAmmo)
end

local function setupCheck()
	local success, result = pcall(function()
		checkReplicatedStorage()
		checkStarterGui()
		checkStarterPlayer()
	end)

	if not success then
		warn("<Pie Hiking Tool (Client)>: please set up ContainerScripts correctly")
		error(result)
	end
end

-- Calling functions
task.defer(setupCheck)