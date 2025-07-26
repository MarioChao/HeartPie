--[[
How to setup Heart Pie's Container Scripts:


----- Manually -----

1. Put things inside "ReplicatedStorage" folder into the "ReplicatedStorage" container service.

2. Put things inside "ServerScriptService" folder into the "ServerScriptService" container service.
--- Make sure the script "PieHikingServer" is enabled.

3. Put things inside "ServerStorage" folder into the "ServerStorage" container service.

4. Put things inside "StartPlayerScripts" folder into the "StarterPlayerScripts" container object, located under the "StarterPlayer" service.
--- Make sure the script "CSCPieAmmo" under CSCPieActor is enabled.
--- Make sure the scripts "ClientPieAmmo" and "ServerPieAmmo" under PieMotionActor are enabled.

5. No need to delete the ContainerScripts folder.


----- Automatically (in studio) -----

1. Select the "HeartPie" tool.

2. Copy the code inside "ContainerSetUp".

3. Paste it in the command bar & run.


----- Automatically (in run time) -----

1. Replace "PieHikingModules" under "ReplicatedStorage" folder with the actual "PieHikingModules" in the "ReplicatedStorage" container service.

2. Do the same for "PieHikingServerStorage" under "ServerStorage".

3. In a server script, require the "ContainerSetUp" module script under the pie tool.
--- The script should preferably be under the "ServerScriptService" container service so that set up is done only once.

Example script:
```
local StarterPack = game:GetService("StarterPack")

require(StarterPack.HeartPie.ContainerSetUp)
```

]]
