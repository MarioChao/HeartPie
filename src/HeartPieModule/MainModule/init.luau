--!strict

-- Heart Pie Main Module


---------- Imports ----------

local _Package = script.HeartPie_Package

local _ContainerScripts = _Package:WaitForChild("ContainerScripts")
local _ReplicatedStorage = _ContainerScripts:WaitForChild("ReplicatedStorage")
local _PieHiking_SharedStorage = _ReplicatedStorage:WaitForChild("PieHiking_SharedStorage")
local _EffectModules = _PieHiking_SharedStorage:WaitForChild("EffectModules")
local _EffectPresets = _EffectModules:WaitForChild("Presets")

local _ServerScriptService = _ContainerScripts:WaitForChild("ServerScriptService")
local _PieHiking_ServerScripts = _ServerScriptService:WaitForChild("PieHiking_ServerScripts")
local _SkinModules = _PieHiking_ServerScripts:WaitForChild("SkinModules")
local _SkinPresets = _SkinModules:WaitForChild("Presets")


---------- Constants ----------

local Constants = {}

Constants.heartPie = _Package:WaitForChild("HeartPie")

Constants.customHitEffectsObjectValue = _EffectPresets:WaitForChild("CustomHitEffectsObjectValue")

Constants.customPieSkinConditionsObjectValue = _SkinPresets:WaitForChild("CustomPieSkinConditionsObjectValue")
Constants.customPieSkinsFolderObjectValue = _SkinPresets:WaitForChild("CustomPieSkinsFolderObjectValue")

table.freeze(Constants)


---------- Module ----------

local Module = {}


----- Module fields -----

function Module.setHitEffectsModule(hitEffectsModule: ModuleScript)
    Constants.customHitEffectsObjectValue.Value = hitEffectsModule
end

function Module.setPieSkins_default(skinsFolder: Folder)
    -- TODO
end

function Module.setPieSkins_conditional(skinsFolder: Folder, skinConditionsModule: ModuleScript)
    Constants.customPieSkinsFolderObjectValue.Value = skinsFolder
    Constants.customPieSkinConditionsObjectValue.Value = skinConditionsModule
end

function Module.setUpAndGetTool()
    require(_Package:WaitForChild("ContainerSetUp"))
    return Constants.heartPie
end


---------- Return module ----------

table.freeze(Module)
return Module
