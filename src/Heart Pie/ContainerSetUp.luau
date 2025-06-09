--!strict
--[[
Automatic Container Set Up Script
Paste in the command bar

Modified from the Pie Hiking plugin
]]


---------- Services ----------

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Selection = game:GetService("Selection")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local StarterPlayer = game:GetService("StarterPlayer")


---------- Instances ----------

local HeartPie
if script then
	HeartPie = script.Parent
elseif RunService:IsEdit() then
	HeartPie = Selection:Get()[1]
end
local HeartPie_ContainerScripts = HeartPie and (HeartPie:FindFirstChild("ContainerScripts (see ReadMe)") or HeartPie:FindFirstChild("ContainerScripts"))
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

local function replaceIfNotFound(parent: Instance, child: Instance)
	local addedInstance = nil
	if not parent:FindFirstChild(child.Name) then
		local newObject = child:Clone()
		newObject.Parent = parent
		addedInstance = newObject
	end
	return addedInstance
end

local function replaceWithNew(parent: Instance, child: Instance)
	removeDupes(parent, child.Name)
	local newObject = child:Clone()
	newObject.Parent = parent
	return newObject
end


---------- Set up functions ----------

local function setUpPieToolContainers(): {Instance}
	local addedInstances = {}

	for _, object in HeartPie_ContainerScripts.ReplicatedStorage:GetChildren() do
		-- Special case
		if object.Name == "PieHikingModules" then
			table.insert(addedInstances, replaceIfNotFound(ReplicatedStorage, object))
			for _, object_2 in object:GetChildren() do
				-- Special case
				if object_2.Name == "PieHitEffects" or object_2.Name == "EffectsList" then
					local newReplaced = replaceIfNotFound(ReplicatedStorage[object.Name], object_2)
					table.insert(addedInstances, newReplaced)
					continue
				end

				local newObject = replaceWithNew(ReplicatedStorage[object.Name], object_2)
				table.insert(addedInstances, newObject)
			end
			continue
		end
		local newObject = replaceWithNew(ReplicatedStorage, object)
		table.insert(addedInstances, newObject)
	end
	for _, object in HeartPie_ContainerScripts.ServerScriptService:GetChildren() do
		local newObject = replaceWithNew(ServerScriptService, object)
		table.insert(addedInstances, newObject)
	end
	for _, object in HeartPie_ContainerScripts.ServerStorage:GetChildren() do
		-- Special case
		if object.Name == "PieHikingServerStorage" then
			table.insert(addedInstances, replaceIfNotFound(ServerStorage, object))
			for _, object_2 in object:GetChildren() do
				-- Special case
				if object_2.Name == "PieSkins" or object_2.Name == "PieSkinConditions" then
					local newReplaced = replaceIfNotFound(ServerStorage[object.Name], object_2)
					table.insert(addedInstances, newReplaced)
					continue
				end

				local newObject = replaceWithNew(ServerStorage[object.Name], object_2)
				table.insert(addedInstances, newObject)
			end
			continue
		end

		local newObject = replaceWithNew(ServerStorage, object)
		table.insert(addedInstances, newObject)
	end
	for _, object in HeartPie_ContainerScripts.StarterPlayerScripts:GetChildren() do
		local newObject = replaceWithNew(StarterPlayer.StarterPlayerScripts, object)
		table.insert(addedInstances, newObject)
	end

	return addedInstances
end


----------- Calling functions ----------

if script then
	setUpPieToolContainers()
else
	ChangeHistoryService:SetWaypoint("Setting up pie container scripts")
	Selection:Set(setUpPieToolContainers())
	ChangeHistoryService:SetWaypoint("Set up pie container scripts")
end

return {}

