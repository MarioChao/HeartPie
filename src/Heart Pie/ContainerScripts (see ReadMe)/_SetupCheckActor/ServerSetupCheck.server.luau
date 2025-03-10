--!strict
-- Server Setup Check Script

---------- Services ----------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

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

---------- Check functions ----------

local function checkReplicatedStorage()
	local PieHikingEvents = checkForChild(ReplicatedStorage, "PieHikingEvents")
	local CSCPieRemoteEvent = checkForChild(PieHikingEvents, "CSCPieRemoteEvent")
	local PieHikeBindable = checkForChild(PieHikingEvents, "PieHikeBindable")
	local PieHikeRemoteEvent = checkForChild(PieHikingEvents, "PieHikeRemoteEvent")

	local PieHikingModules = checkForChild(ReplicatedStorage, "PieHikingModules")
	local RegularPieAmmoModule = checkForChild(PieHikingModules, "RegularPieAmmoModule")
end

local function checkServerScriptService()
	local PieHikingScripts = checkForChild(ServerScriptService, "PieHikingScripts")
	local PieHikingActor = checkForChild(PieHikingScripts, "PieHikingActor")
	local PieHikingServer: Script = checkForChild(PieHikingActor, "PieHikingServer")
	local ServerPieMotionActor = checkForChild(PieHikingScripts, "ServerPieMotionActor")
	local ServerPieAmmo: Script = checkForChild(ServerPieMotionActor, "ServerPieAmmo")
	local PieSkinsChecker: Script = checkForChild(PieHikingScripts, "PieSkinsChecker")
	checkScriptEnabled(PieHikingServer)
	checkScriptEnabled(ServerPieAmmo)
	checkScriptEnabled(PieSkinsChecker)
end

local function checkServerStorage()
	local PieHikingServerStorage = checkForChild(ServerStorage, "PieHikingServerStorage")
	local PieHikingServerEvents = checkForChild(PieHikingServerStorage, "PieHikingServerEvents")
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

---------- Calling functions ----------

task.defer(setupCheck)

---------- Delete container scripts in tool ----------

task.delay(1, function()
	script.Parent.Parent:Destroy()
end)
