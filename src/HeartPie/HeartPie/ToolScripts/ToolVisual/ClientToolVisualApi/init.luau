--!strict

-- Client Tool Visual Api


---------- Validate environment ----------

local RunService = game:GetService("RunService")

if not RunService:IsClient() then
    warn(`[Client Tool Visual Api]: Module should only be called from the Client!`)
end


---------- Constants ----------

local Constants = {}

Constants.apiBindableEvent = script:WaitForChild("ApiBindableEvent")

table.freeze(Constants)


---------- Module ----------

local Module = {}


----- Module fields -----

function Module.setPieTransparency(transparency: number?)
	Constants.apiBindableEvent:Fire("Set Pie Transparency", transparency)
end


---------- Return module ----------

table.freeze(Module)
return Module
