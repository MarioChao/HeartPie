--!strict

-- Heart Pie Main Module


---------- Imports ----------

local _Package = script.HeartPie_Package

local _ContainerScripts = _Package:WaitForChild("ContainerScripts")
local _ReplicatedStorage = _ContainerScripts:WaitForChild("ReplicatedStorage")
local _PieHikingSharedStorage = _ReplicatedStorage:WaitForChild("PieHikingSharedStorage")
local _EffectModules = _PieHikingSharedStorage:WaitForChild("EffectModules")
local _Presets = _EffectModules:WaitForChild("Presets")


---------- Constants ----------

local Constants = {}

Constants.heartPie = _Package:WaitForChild("HeartPie")

Constants.customHitEffectsObjectValue = _Presets:WaitForChild("CustomHitEffectsObjectValue")

table.freeze(Constants)


---------- Module ----------

local Module = {}


----- Module fields -----

function Module.setHitEffectsModule(hitEffectsModule: ModuleScript)
    Constants.customHitEffectsObjectValue.Value = hitEffectsModule
end

function Module.setPieSkins(skinsFolder: Folder)
end

function Module.setUpAndGetTool()
    require(_Package:WaitForChild("ContainerSetUp"))
    return Constants.heartPie
end


---------- Return module ----------

table.freeze(Module)
return Module
