--!strict
--[[
Automatic Container Set Up Script
Paste in the command bar

Modified from the Pie Hiking plugin
]]

---------- Services ----------

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Selection = game:GetService("Selection")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local HeartPie = Selection:Get()[1]
local HeartPie_ContainerScripts = HeartPie:FindFirstChild("ContainerScripts (see ReadMe)") or HeartPie:FindFirstChild("ContainerScripts")
local canSetUp = (
	(HeartPie_ContainerScripts and HeartPie_ContainerScripts:IsA("Folder"))
	and HeartPie_ContainerScripts:FindFirstChild("ReplicatedStorage")
)
if not canSetUp then
	warn("Select the pie Tool first!")
	return
end

---------- Local functions ----------

local function removeDupes(parent: Instance, childName: string)
	while true do
		local dupe = parent:FindFirstChild(childName)
		if not dupe then
			break
		end
		dupe.Parent = nil
	end
end

local function setUpPieToolContainers(): {Instance}
	local addedInstances = {}

	for _, object in HeartPie_ContainerScripts.ReplicatedStorage:GetChildren() do
		removeDupes(ReplicatedStorage, object.Name)
		local newObject = object:Clone()
		newObject.Parent = ReplicatedStorage
		table.insert(addedInstances, newObject)
	end
	for _, object in HeartPie_ContainerScripts.ServerScriptService:GetChildren() do
		removeDupes(ServerScriptService, object.Name)
		local newObject = object:Clone()
		newObject.Parent = ServerScriptService
		table.insert(addedInstances, newObject)
	end
	for _, object in HeartPie_ContainerScripts.ServerStorage:GetChildren() do
		removeDupes(ServerStorage, object.Name)
		local newObject = object:Clone()
		newObject.Parent = ServerStorage
		table.insert(addedInstances, newObject)
	end
	for _, object in HeartPie_ContainerScripts.StarterPlayerScripts:GetChildren() do
		removeDupes(StarterPlayer.StarterPlayerScripts, object.Name)
		local newObject = object:Clone()
		newObject.Parent = StarterPlayer.StarterPlayerScripts
		table.insert(addedInstances, newObject)
	end

	return addedInstances
end

----------- Calling functions ----------

ChangeHistoryService:SetWaypoint("Setting up pie container scripts")
setUpPieToolContainers()
ChangeHistoryService:SetWaypoint("Set up pie container scripts")
