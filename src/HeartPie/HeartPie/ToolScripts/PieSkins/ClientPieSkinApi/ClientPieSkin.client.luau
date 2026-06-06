--!strict

-- Client Pie Skin


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


---------- Constants ----------

local Constants = {}

Constants.apiBindableEvent = script.Parent:WaitForChild("ApiBindableEvent")

table.freeze(Constants)


---------- Local functions ----------

local changeSkinIdBy


----- Change skin -----

changeSkinIdBy = function(amount: number)
	BelovedRemote.fire_toServer("Change Skin Id By", amount)
end


----- Main -----

local function main()
	Constants.apiBindableEvent.Event:Connect(function(mode: string, ...)
		if mode == "Change Skin Id By" then
			changeSkinIdBy(...)
		end
	end)
end


---------- Calling function ----------

main()
