--!strict

-- Heart Pie Main Module


---------- Imports ----------

local _Package = script.HeartPie_Package

local _ContainerScripts = _Package:WaitForChild("ContainerScripts")
local _ReplicatedStorage = _ContainerScripts:WaitForChild("ReplicatedStorage")
local _PieHiking_SharedStorage = _ReplicatedStorage:WaitForChild("PieHiking_SharedStorage")
local _EffectModules = _PieHiking_SharedStorage:WaitForChild("EffectModules")
local _EffectPresets = _EffectModules:WaitForChild("Presets")

local _SoundModules = _PieHiking_SharedStorage:WaitForChild("SoundModules")
local _SoundPresets = _SoundModules:WaitForChild("Presets")

local _ServerScriptService = _ContainerScripts:WaitForChild("ServerScriptService")
local _PieHiking_ServerScripts = _ServerScriptService:WaitForChild("PieHiking_ServerScripts")
local _SkinModules = _PieHiking_ServerScripts:WaitForChild("SkinModules")
local _SkinPresets = _SkinModules:WaitForChild("Presets")


---------- Constants ----------

local Constants = {}

Constants.heartPie = _Package:WaitForChild("HeartPie")

do
    local _ToolValues = Constants.heartPie:WaitForChild("ToolValues")
    Constants.toolConfig = _ToolValues:WaitForChild("ToolConfig")
end

Constants.customHitEffectsObjectValue = _EffectPresets:WaitForChild("CustomHitEffectsObjectValue")

Constants.customSoundEffectsObjectValue = _SoundPresets:WaitForChild("CustomSoundEffectsObjectValue")

Constants.customStarterPieSkinsFolderObjectValue = _SkinPresets:WaitForChild("CustomStarterPieSkinsFolderObjectValue")
Constants.customPieSkinConditionsObjectValue = _SkinPresets:WaitForChild("CustomPieSkinConditionsObjectValue")
Constants.customConditionalPieSkinsFolderObjectValue = _SkinPresets:WaitForChild("CustomConditionalPieSkinsFolderObjectValue")

table.freeze(Constants)


---------- Module ----------

local Module = {}


----- Module fields -----

function Module.setHitEffectsModule(hitEffectsModule: ModuleScript)
    Constants.customHitEffectsObjectValue.Value = hitEffectsModule
end

function Module.setSoundEffectsModule(soundEffectsModule: ModuleScript)
    Constants.customSoundEffectsObjectValue.Value = soundEffectsModule
end

function Module.setPieSkins_starter(skinsFolder: Folder)
    Constants.customStarterPieSkinsFolderObjectValue.Value = skinsFolder
end

function Module.setPieSkins_conditional(skinsFolder: Folder, skinConditionsModule: ModuleScript)
    Constants.customConditionalPieSkinsFolderObjectValue.Value = skinsFolder
    Constants.customPieSkinConditionsObjectValue.Value = skinConditionsModule
end

function Module.getToolConfig()
    return Constants.toolConfig
end

function Module.setUpAndGetTool()
    require(_Package:WaitForChild("ContainerSetUp"))
    return Constants.heartPie
end


---------- Return module ----------

table.freeze(Module)
return Module
