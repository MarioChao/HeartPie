--!strict
-- Client Setup Check Script

---------- Services ----------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local StarterPlayer = game:GetService("StarterPlayer")

---------- Local functions ----------

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
	local PieHikeBindable = checkForChild(PieHikingEvents, "PieHikeBindable")
	local PieHikeRemoteEvent = checkForChild(PieHikingEvents, "PieHikeRemoteEvent")

	local PieHikingModules = checkForChild(ReplicatedStorage, "PieHikingModules")
	local RegularPieAmmoModule = checkForChild(PieHikingModules, "RegularPieAmmoModule")
end

local function checkStarterPlayer()
	local StarterPlayerScripts = checkForChild(StarterPlayer, "StarterPlayerScripts")
	local PieHikingPlayerScripts = checkForChild(StarterPlayerScripts, "PieHikingPlayerScripts")
	local CSCPieMotionActor = checkForChild(PieHikingPlayerScripts, "CSCPieMotionActor")
	local CSCPieAmmo = checkForChild(CSCPieMotionActor, "CSCPieAmmo") :: Script
	local CSCPieAmmoModule = checkForChild(CSCPieMotionActor, "CSCPieAmmoModule")
	local PieMotionActor = checkForChild(PieHikingPlayerScripts, "PieMotionActor")
	local ClientPieAmmo = checkForChild(PieMotionActor, "ClientPieAmmo") :: Script
	checkScriptEnabled(CSCPieAmmo)
	checkScriptEnabled(ClientPieAmmo)
end

local function setupCheck()
	local success, result = pcall(function()
		checkReplicatedStorage()
		checkStarterPlayer()
	end)

	if not success then
		warn("<Pie Hiking Tool (Client)>: please set up ContainerScripts correctly")
		error(result)
	end
end

---------- Calling functions ----------

task.defer(setupCheck)
