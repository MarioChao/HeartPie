local ChangeHistoryService = game:GetService("ChangeHistoryService")
--[[
How to setup Heart Pie's Container Scripts:

1. Put things inside "ReplicatedStorage" folder into the "ReplicatedStorage" container service.

2. Put things inside "ServerScriptService" folder into the "ServerScriptService" container service.
--- Make sure the script "PieHikingServer" is enabled.

3. Put things inside "StartPlayerScripts" folder into the "StarterPlayerScripts" container object, located under the "StarterPlayer" service.
--- Make sure the script "CSCPieAmmo" under CSCPieActor is enabled.
--- Make sure the scripts "ClientPieAmmo" and "ServerPieAmmo" under PieMotionActor are enabled.

4. Put things inside "ServerStorage" folder into the "ServerStorage" container service.

5. Delete the "ContainerScripts" folder.
]]

--[[
Automatic setup script
- From the Pie Hiking plugin
]]
do
	local CHS = game:GetService("ChangeHistoryService")
	CHS:SetWaypoint("Setting up pie container scripts")

	-- Services

	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Selection = game:GetService("Selection")
	local ServerScriptService = game:GetService("ServerScriptService")
	local ServerStorage = game:GetService("ServerStorage")
	local StarterPlayer = game:GetService("StarterPlayer")

	local HeartPie_ContainerScripts = Selection:Get()[1]
	local canSetUp = (
		(HeartPie_ContainerScripts and HeartPie_ContainerScripts:IsA("Folder"))
		and HeartPie_ContainerScripts:FindFirstChild("ReplicatedStorage")
	)
	if not canSetUp then
		warn("Select the ContainerScripts folder first!")
		return
	end

	-- Functions

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

	setUpPieToolContainers()
	CHS:SetWaypoint("Set up pie container scripts")
end
