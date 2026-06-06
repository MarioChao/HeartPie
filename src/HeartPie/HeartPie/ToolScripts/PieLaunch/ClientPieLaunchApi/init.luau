--!strict

-- Client Pie Launch Api


---------- Validate environment ----------

local RunService = game:GetService("RunService")

if not RunService:IsClient() then
    warn(`[Client Pie Launch Api]: Module should only be called from the Client!`)
end


---------- Constants ----------

local Constants = {}

Constants.apiBindableEvent = script:WaitForChild("ApiBindableEvent")

table.freeze(Constants)


---------- Module ----------

local Module = {}


----- Module fields -----

function Module.launchClientPie(launchMotion: {["CFrame"]: CFrame?, ["Direction"]: Vector3?})
	Constants.apiBindableEvent:Fire("Launch Client Pie", launchMotion)
end


---------- Return module ----------

table.freeze(Module)
return Module
