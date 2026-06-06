--!strict

-- Client Pie Skin Api


---------- Validate environment ----------

local RunService = game:GetService("RunService")

if not RunService:IsClient() then
    warn(`[Client Pie Skin Api]: Module should only be called from the Client!`)
end


---------- Constants ----------

local Constants = {}

Constants.apiBindableEvent = script:WaitForChild("ApiBindableEvent")

table.freeze(Constants)


---------- Module ----------

local Module = {}


----- Module fields -----

function Module.changeSkinIdBy(amount: number)
	Constants.apiBindableEvent:Fire("Change Skin Id By", amount)
end


---------- Return module ----------

table.freeze(Module)
return Module
