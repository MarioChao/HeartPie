--!strict

-- Client Pie Ammo Api


---------- Services ----------

local RunService = game:GetService("RunService")


---------- Constants ----------

local Constants = {}

Constants.apiBindableEvent = script:WaitForChild("ApiBindableEvent")

table.freeze(Constants)


---------- Module ----------

local Module = {}


----- Module fields -----

function Module.createAndLaunch(ammoModel: Model)
	if not RunService:IsClient() then
		warn(`[Client Pie Ammo Api]: Module should only be called from the Client!`)
		return
	end
	Constants.apiBindableEvent:Fire("Create and Launch", ammoModel)
end


---------- Return module ----------

table.freeze(Module)
return Module
