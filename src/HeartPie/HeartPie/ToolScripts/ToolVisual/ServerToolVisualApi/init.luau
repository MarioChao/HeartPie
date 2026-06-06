--!strict

-- Server Tool Visual Api


---------- Validate environment ----------

local RunService = game:GetService("RunService")

if not RunService:IsServer() then
    warn(`[Server Tool Visual Api]: Module should only be called from the Server!`)
end


---------- Constants ----------

local Constants = {}

Constants.apiBindableEvent = script:WaitForChild("ApiBindableEvent")

table.freeze(Constants)


---------- Module ----------

local Module = {}


----- Module fields -----

function Module.renewPieTransparency()
	Constants.apiBindableEvent:Fire("Renew Pie Transparency")
end


---------- Return module ----------

table.freeze(Module)
return Module
