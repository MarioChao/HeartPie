--[[
How to set up Heart Pie's Container Scripts:


----- Manually -----

1. Put things inside "ReplicatedStorage" folder into the "ReplicatedStorage" container service.

2. Put things inside "ServerScriptService" folder into the "ServerScriptService" container service.


----- Automatically (in studio) -----

1. Copy the code inside "ContainerSetUp".

2. Select the "HeartPie_Package" folder.

3. Paste the copied code in the command bar & run.


----- Automatically (in run time) -----

1. In a server script, require the "ContainerSetUp" module script under the pie package Folder.
--- The script should preferably be under the "ServerScriptService" container service so that set up is done only once.


----- Automatically (run time advanced) -----

1. Require the "MainModule" module script under the "HeartPie_Module" folder.

2. Call functions to customize hit effects and pie skins.

3. Call "setUpAndGetTool()" to set up container scripts and retrieve the tool.

Example script:
```
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local replicatedPresets = ReplicatedStorage.CustomData.Presets
local skinPresets = ServerScriptService.CustomSkinsData.Presets

local hpm = require(ServerStorage.HeartPie_Module.MainModule)

hpm.setHitEffectsModule(replicatedPresets.NewHitEffects)
hpm.setSoundEffectsModule(replicatedPresets.NewSoundEffects)
hpm.setPieSkins_conditional(skinPresets.NewCondPieSkinsFolder, skinPresets.NewPieSkinConditions)

local tool = hpm.setUpAndGetTool()

for _, player in game:GetService("Players"):GetPlayers() do
	tool:Clone().Parent = player.Backpack
end
tool.Parent = game:GetService("StarterPack")
```
]]
