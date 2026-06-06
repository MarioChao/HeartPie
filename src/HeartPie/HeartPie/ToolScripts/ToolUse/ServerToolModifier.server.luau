--!strict

-- Server Tool Modifier


---------- Validate container ----------

-- Under data model (for plugin)
if not script:FindFirstAncestorWhichIsA("DataModel") then
	return
end


---------- Services ----------

local ReplicatedStorage = game:GetService("ReplicatedStorage")


---------- Imports ----------

local _PieHiking_SharedStorage = ReplicatedStorage:WaitForChild("PieHiking_SharedStorage")
local _Modules = _PieHiking_SharedStorage:WaitForChild("Modules")
local BelovedRemote = require(_Modules:WaitForChild("BelovedRemote"))

local _ToolScripts = script.Parent.Parent
local Tooling = require(_ToolScripts:WaitForChild("Tooling"))


---------- Local functions ----------

local setPieLaunchType


----- Pie type -----

setPieLaunchType = function(caller: Player, newLaunchType: string)
	-- Sanity check for switching type
	if not Tooling.configs.getCanSwitchType() then
		return
	end

	-- Validate player
	if caller ~= Tooling.getOwner() then
		return
	end

	-- Set pie launch type
	if newLaunchType == "Client" or newLaunchType == "Server" then
		local isClientPieType = (newLaunchType == "Client")
		Tooling.toolConfig:SetAttribute("IsClientPieType", isClientPieType)
	end
end


----- Main -----

local function main()
	BelovedRemote.connect_toServer("Server Set Pie Launch Type", setPieLaunchType)
end


---------- Calling function ----------

main()
