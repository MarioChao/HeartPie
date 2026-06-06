--[[

The Heart Pie Module allows easy customization and set up for the Heart Pie.

Customizations include hit effects, sound effects, pie skins, and tool config.


Example script:

```
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local StarterPack = game:GetService("StarterPack")

local replicatedPresets = ReplicatedStorage.CustomData.Presets
local skinPresets = ServerScriptService.CustomSkinsData.Presets

-- Optionally use 98579925732882
local hpm = require(ServerStorage.HeartPie_Module.MainModule)

-- Hit & sound effects (Replicated)
hpm.setHitEffectsModule(replicatedPresets.NewHitEffects)
hpm.setSoundEffectsModule(replicatedPresets.NewSoundEffects)

-- Pie skins (Server)
hpm.setPieSkins_starter(skinPresets.NewStarterPieSkinsFolder)
hpm.setPieSkins_conditional(skinPresets.NewCondPieSkinsFolder, skinPresets.NewPieSkinConditions)

-- Configure beginner pie
local toolConfig = hpm.getToolConfig()
toolConfig:SetAttribute("CanCollideThrower", false)
toolConfig:SetAttribute("LaunchOffsetStuds", 0)
toolConfig:SetAttribute("LaunchVelocity", 95)

-- Set up & get tool
local tool = hpm.setUpAndGetTool()

-- Parent to starter pack
for _, player in Players:GetPlayers() do
	tool:Clone().Parent = player.Backpack
end
tool.Parent = StarterPack
```

]]
