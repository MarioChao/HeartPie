--!strict

-- Automatic Container Set Up Script


---------- Services ----------

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Selection = game:GetService("Selection")
local ServerScriptService = game:GetService("ServerScriptService")


---------- Types ----------

type FilePath = {[string]: FilePath}


---------- Constants ----------

local Constants = {}

if script then
	Constants.HeartPie_Package = script.Parent
elseif RunService:IsEdit() then
	Constants.HeartPie_Package = Selection:Get()[1]
end
Constants.HeartPie_ContainerScripts = Constants.HeartPie_Package and Constants.HeartPie_Package:FindFirstChild("ContainerScripts")
Constants.canSetUp = (
	(Constants.HeartPie_ContainerScripts and Constants.HeartPie_ContainerScripts:IsA("Folder"))
	and Constants.HeartPie_ContainerScripts:FindFirstChild("ReplicatedStorage")
)
if not Constants.canSetUp then
	warn("Select the pie package Folder first!")
	return {}
end

table.freeze(Constants)


---------- Local functions ----------

local removeDupes
local replaceIfNotFound
local replaceWithNew
local cloneReparentRecursive

local setUpPieToolContainers


----- Replacement -----

removeDupes = function(parent: Instance, childName: string)
	while true do
		local dupe = parent:FindFirstChild(childName)
		if not dupe then
			break
		end
		dupe.Parent = nil
	end
end

replaceIfNotFound = function(parent: Instance, child: Instance)
	local addedInstance = nil
	if not parent:FindFirstChild(child.Name) then
		local newObject = child:Clone()
		newObject.Parent = parent
		addedInstance = newObject
	end
	return addedInstance
end

replaceWithNew = function(parent: Instance, child: Instance)
	removeDupes(parent, child.Name)
	local newObject = child:Clone()
	newObject.Parent = parent
	return newObject
end

cloneReparentRecursive = function(oldParent: Instance, newParent: Instance, doNotReplacePaths: FilePath): {Instance}
	local addedInstances = {}
	for _, child in oldParent:GetChildren() do
		-- Check do not replace
		if doNotReplacePaths[child.Name] then
			-- Replace if not found
			local replacedObject = replaceIfNotFound(newParent, child)
			table.insert(addedInstances, replacedObject)

			-- Reparent recursive
			local newParentChild = newParent:FindFirstChild(child.Name) or replacedObject
			local tempInstances = cloneReparentRecursive(child, newParentChild, doNotReplacePaths[child.Name])
			table.move(tempInstances, 1, #tempInstances, #addedInstances + 1, addedInstances)
			continue
		end

		-- Replace
		table.insert(addedInstances, replaceWithNew(newParent, child))
	end
	return addedInstances
end


----- Set up -----

setUpPieToolContainers = function(): {Instance}
	local addedInstances = {}
	local tempInstances: {Instance}
	local containerScripts = Constants.HeartPie_ContainerScripts

	-- Replicated storage
	tempInstances = cloneReparentRecursive(containerScripts.ReplicatedStorage, ReplicatedStorage, {
		PieHiking_SharedStorage = {
			EffectModules = {
				Presets = {
					DefaultHitEffects = {},
					CustomHitEffectsObjectValue = {},
				},
			},
			SoundModules = {
				Presets = {
					DefaultSoundEffects = {},
					CustomSoundEffectsObjectValue = {},
				}
			},
		},
	})
	table.move(tempInstances, 1, #tempInstances, #addedInstances + 1, addedInstances)

	-- Server script service
	tempInstances = cloneReparentRecursive(containerScripts.ServerScriptService, ServerScriptService, {
		PieHiking_ServerScripts = {
			SkinModules = {
				Presets = {
					DefaultConditionalPieSkinsFolder = {},
					DefaultStarterPieSkinsFolder = {},
					DefaultPieSkinConditions = {},
					CustomConditionalPieSkinsFolderObjectValue = {},
					CustomStarterPieSkinsFolderObjectValue = {},
					CustomPieSkinConditionsObjectValue = {},
				},
			},
		},
	})
	table.move(tempInstances, 1, #tempInstances, #addedInstances + 1, addedInstances)

	return addedInstances
end


----- Main -----

local function main()
	if script then
		setUpPieToolContainers()
	else
		ChangeHistoryService:SetWaypoint("Setting up pie container scripts")
		Selection:Set(setUpPieToolContainers())
		ChangeHistoryService:SetWaypoint("Set up pie container scripts")
	end
end


----------- Calling function ----------

main()


---------- Return module ----------

return {}
