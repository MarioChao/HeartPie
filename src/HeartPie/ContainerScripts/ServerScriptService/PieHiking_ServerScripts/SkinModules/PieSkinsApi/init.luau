--!strict

-- Pie Skins Api


---------- Constants ----------

local Constants = {}

do
	local _ApiBindables = script:WaitForChild("ApiBindables")
	Constants.apiBindableEvent = _ApiBindables:WaitForChild("ApiBindableEvent")
	Constants.apiBindableFunction = _ApiBindables:WaitForChild("ApiBindableFunction")
end

table.freeze(Constants)


---------- Module ----------

local Module = {}


----- Module fields -----

function Module.saveUserSkinId(userId: number, skinId: number)
    Constants.apiBindableEvent:Fire("Save User Skin Id", userId, skinId)
end

function Module.getUserSkinId(userId: number)
    return Constants.apiBindableFunction:Invoke("Get User Skin Id", userId)
end

function Module.populateToolSkins(pieTool: Tool)
    Constants.apiBindableEvent:Fire("Populate Tool Skins", pieTool)
end


---------- Return module ----------

table.freeze(Module)
return Module
