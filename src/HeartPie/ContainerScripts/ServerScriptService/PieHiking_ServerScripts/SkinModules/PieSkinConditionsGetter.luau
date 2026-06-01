--!strict

-- Pie Skin Conditions Getter


---------- Imports ----------

local _Presets = script.Parent:WaitForChild("Presets")
local PieSkinConditions = (function()
	-- Import default
	local DefaultPieSkinConditions = require(_Presets:WaitForChild("DefaultPieSkinConditions"))

	-- Attempt to import & return custom
	local _CustomPieSkinConditionsObjectValue = _Presets:WaitForChild("CustomPieSkinConditionsObjectValue")
	if _CustomPieSkinConditionsObjectValue.Value then
		local pcallSuccess, CustomPieSkinConditions = pcall(function()
			return require(_CustomPieSkinConditionsObjectValue.Value) :: typeof(DefaultPieSkinConditions)
		end)
		if pcallSuccess then
			return CustomPieSkinConditions
		end
	end

	-- Return default
	return DefaultPieSkinConditions
end)()


---------- Module ----------

local Module = {}


----- Module fields -----

function Module.getValueAt(name: string)
	return PieSkinConditions[name]
end

function Module.getTable()
	return PieSkinConditions
end


---------- Return module ----------

table.freeze(Module)
return Module
