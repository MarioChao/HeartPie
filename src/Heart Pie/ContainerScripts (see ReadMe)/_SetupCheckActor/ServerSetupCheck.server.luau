--!strict
-- Server Setup Check Script

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Function
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

local function checkServerScriptService()
	local PieHikingScripts = checkForChild(ServerScriptService, "PieHikingScripts")
	local PieHikingActor = checkForChild(PieHikingScripts, "PieHikingActor")
	local PieHikingServer = checkForChild(PieHikingActor, "PieHikingServer") :: Script
	checkScriptEnabled(PieHikingServer)
end

local function setupCheck()
	local success, result = pcall(function()
		checkReplicatedStorage()
		checkServerScriptService()
	end)
	
	if not success then
		warn("<Pie Hiking Tool (Server)>: please set up ContainerScripts correctly")
		error(result)
	end
end

-- Calling functions
task.defer(setupCheck)