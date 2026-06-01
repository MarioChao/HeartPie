--!strict

-- Client Pie Ammo Api


---------- Services ----------

local RunService = game:GetService("RunService")


---------- Constants ----------

local Constants = {}

Constants.apiBindableEvent = script:WaitForChild("ApiBindableEvent")

table.freeze(Constants)


---------- Local functions ----------

----- Main -----

local function main()
	if not RunService:IsClient() then
		warn(`[Client Pie Ammo Api]: Module should only be called from the Client!`)
	end
end


---------- Calling function ----------

main()


---------- Module ----------

local Module = {}


----- Module fields -----

function Module.createAndLaunch(ammoModel: Model)
	Constants.apiBindableEvent:Fire("Create and Launch", ammoModel)
end


---------- Return module ----------

table.freeze(Module)
return Module
