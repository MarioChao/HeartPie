--!strict

-- Client Tool Use Api


---------- Validate environment ----------

local RunService = game:GetService("RunService")

if not RunService:IsClient() then
    warn(`[Client Tool Use Api]: Module should only be called from the Client!`)
end


---------- Constants ----------

local Constants = {}

Constants.apiBindableEvent = script:WaitForChild("ApiBindableEvent")

table.freeze(Constants)


---------- Module ----------

local Module = {}


----- Module fields -----

function Module.launchPie()
	Constants.apiBindableEvent:Fire("Launch Pie")
end

function Module.setPieLaunchType(launchType: "Client" | "Server")
	Constants.apiBindableEvent:Fire("Set Pie Launch Type", launchType)
end


---------- Return module ----------

table.freeze(Module)
return Module
