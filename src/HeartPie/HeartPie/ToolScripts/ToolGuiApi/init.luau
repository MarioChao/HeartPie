--!strict

-- Tool Gui Api


---------- Validate environment ----------

local RunService = game:GetService("RunService")

if not RunService:IsClient() then
    warn(`[Tool Gui Api]: Module should only be called from the Client!`)
end


---------- Constants ----------

local Constants = {}

Constants.apiBindableEvent = script:WaitForChild("ApiBindableEvent")

table.freeze(Constants)


---------- Module ----------

local Module = {}


----- Module fields -----

function Module.switchPieType()
	Constants.apiBindableEvent:Fire("Switch Pie Type")
end


---------- Return module ----------

table.freeze(Module)
return Module
