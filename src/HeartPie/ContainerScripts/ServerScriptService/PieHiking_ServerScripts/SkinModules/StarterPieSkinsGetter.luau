--!strict

-- Starter Pie Skins Getter


---------- Imports ----------

local _Presets = script.Parent:WaitForChild("Presets")
local PieSkinsFolder = (function()
	-- Import default
	local DefaultPieSkinsFolder = _Presets:WaitForChild("DefaultStarterPieSkinsFolder")

	-- Attempt to import & return custom
	local _CustomPieSkinsFolderObjectValue = _Presets:WaitForChild("CustomStarterPieSkinsFolderObjectValue")
	if _CustomPieSkinsFolderObjectValue.Value then
		local pcallSuccess, CustomPieSkinsFolder = pcall(function()
			return _CustomPieSkinsFolderObjectValue.Value :: typeof(DefaultPieSkinsFolder)
		end)
		if pcallSuccess then
			return CustomPieSkinsFolder
		end
	end

	-- Return default
	return DefaultPieSkinsFolder
end)()

local SkinUtil = require(script.Parent:WaitForChild("SkinUtil"))


---------- Globals ----------

local Globals = {}

Globals.pieSkins = {} :: {[string]: Model}


---------- Local functions ----------

local initializePieSkinsTable


----- Pie skins -----

initializePieSkinsTable = function()
	Globals.pieSkins = {}
	for _, model in PieSkinsFolder:GetChildren() do
		if SkinUtil.getIsSkinModel(model) then
			Globals.pieSkins[model.Name] = model
		end
	end
end


----- Main -----

local function main()
	initializePieSkinsTable()
end


---------- Calling function ----------

main()


---------- Module ----------

local Module = {}


----- Module fields -----

function Module.getValueAt(name: string)
	return Globals.pieSkins[name]
end

function Module.getTable()
	return Globals.pieSkins
end


---------- Return module ----------

table.freeze(Module)
return Module
