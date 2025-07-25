# Changelog and Plans


## Plans

- [+] Allow pies to be visible if they are initially in the workspace.
- [ ] Allow unstick & remove time to be modified.
- [ ] Move `PieHikingEvents` and `PieHikingModules` into `PieHikingSharedStorage`


## [1.0.10] Auto Reload + Reload Show Pie | 2025/07/25

Added auto reloading the pie through the `AutoReload` attribute (enabled by default).

Toggle whether pie is visible during reloading through the `ReloadShowPie` attribute (disabled by default).

> [!TIP]
>
> Replace the scripts [PieHandler](src/Heart%20Pie/ToolScripts/ToolUseActor/PieHandler.client.luau)
> and [ClientToolVisual](src/Heart%20Pie/ToolScripts/ToolVisualActor/ClientToolVisual.client.luau).
>
> Add boolean attributes `AutoReload` and `ReloadShowPie` to the pie tool.


## Fixed Respawn Speed Glitch + Improved Touch Button + Removed Skin Change Cooldown | 2025/07/16

Fixed a speed glitch upon respawning due to conditional skins stored in the `ContainerScripts` folder.
(thanks Nexusity)

Modified the touch buttons for switching skins:
- Added titles "Prev" and "Next" to the buttons
- Positioned the buttons next to each other

Removed the 0.1s cooldown for changing pie skins.

> [!TIP]
>
> Replace the scripts [ContextActions](src/Heart%20Pie/ToolScripts/ActionsActor/ContextActions.client.luau),
> [ClientPieSkin](src/Heart%20Pie/ToolScripts/PieSkinsActor/ClientPieSkin.client.luau),
> [ServerPieSkin](src/Heart%20Pie/ToolScripts/PieSkinsActor/ServerPieSkin.server.luau),
> and [ServerToolVisual](src/Heart%20Pie/ToolScripts/ToolVisualActor/ServerToolVisual.server.luau).


## Badge Check Optimization + Container Set Up Fix | 2025/06/09

`BadgeCheck` module scripts are now renewed with more optimizations.<br>
They are copied from the ones used in [Pie Hiker License](https://github.com/MarioChao/Pie-Hiker-License).

Fixed container not setting up correctly when `PieHikingModules` or `PieHikingServerStorage` are missing from the container services.


## Run Time Tool Setup & Badge Check Adjustment | 2025/06/05

Modified `ContainerSetUp` into a module script under the pie tool.<br>
This allows for run time tool setup:

- In a server script under `ServerScriptService`, require the `ContainerSetUp` module script under a pie tool to directly set up the necessary container scripts.
- Make sure that pie effects & conditional pie skins are placed into the `ContainerScripts` folder:
    - Replace `ReplicatedStorage` > `PieHikingModules` with a customized one (for pie effects).
    - Replace `ServerStorage` > `PieHikingServerStorage` with a customized one (for conditional pie skins).

Slightly modified the `BadgeCheck` module scripts:

- New `BadgeCheckHelper` module script, which separates badge check from result caching.
    - This script is identical to one used in [Pie Hiking Difficulty Test](https://www.roblox.com/games/16124983043/Pie-Hiking-Difficulty-Test).
- The `BadgeCheck` now caches results from `BadgeCheckHelper` for 64 seconds (previously 352 seconds).


## Small Refactor & Fix | 2025/03/10

Moved a file:
- `PieHikingServerEvents` into `PieHikingServerStorage`

Modified `ContainerSetUp` script to not replaced certain config files:
- `PieHitEffects` and `EffectsList`
- `PieSkins` and `PieSkinConditions`


## Improved Pie Skins System | 2025/02/23

Checklist done:

- Improve how skins are unlocked.
- Improve the design of pie effects.

Revamped the pie skins system:

- [x] Automatically add skins when they are parented to the `PieSkins` folder.
- [x] Conditional skins:
    - Stored in server storage.
    - Given to players after some server-sided checks.
- [x] Hit effects are now stored in a single module script inside ReplicatedStorage.
- [x] Selected pie skin saves within the same session / server.
    - Id saves each time the player swaps the skin.

**emitLegacyScripts** is set to true to avoid warnings in Roblox Studio.

A container setup script can be found in [ReadMe](./src/Heart%20Pie/ContainerScripts%20(see%20ReadMe)/ReadMe.server.luau).<br>
This script is similar to the one found in Pie Hiking plugin.


## Server-side Collision & Improvements | 2024/09/07

Many thanks to LunarK (Ori) for helping me with fixing the server pie.

Changed the "Server" pie type such that:

- The pie is owned by the server (network ownership).
- It is handled by a server script.
- The pie will be not-collidable with characters that can't be hit.

`PieAmmoModule` is moved to `ReplicatedStorage` and renamed into `RegularPieAmmoModule`.

Tool inputs:

- Tool inputs are moved to the [ContextActions](./src/Heart%20Pie/ToolScripts/ActionsActor/ContextActions.client.luau) script.
- Press `T` to switch the pie type.

`PieToolScreen` can be customized by putting one in StarterGui.<br>
The default `PieToolScreen` will be used if none is found.

New number value `TimeUntilUnstick` under the pie model.<br>
...


## Overlap Part | 2024/08/20

Thanks to drumpiece for motivating me to do this update.

Added a feature `CanOverlapPart` which prevents the pie from being "pushed out" when sticking.<br>
Enabling this attribute under `PieModel` could raise the difficulty of pie hiking.


## Stick After 7.5 s | 2024/08/02

Small modifications to some container scripts.

Pies no longer stick if they first touched a part 7.5 seconds after launch.


## Porting Progress | 2024/6/22 - 6/23

Ported the Heart Pie model to [Rojo](https://github.com/rojo-rbx/rojo):

- [x] ContainerScripts
- [x] PieSkins
- [x] ToolEvents
- [x] ToolScripts
- [x] ToolValues
- [x] PieModel
- [x] Handle

Also, changed the name from `Heart Pie 2024` to `Heart Pie`.


## Attribute Configurations | 2024/5/29 - 5/30

Changed most configurations from [value instances](https://create.roblox.com/docs/reference/engine/classes/ValueBase) to [attributes](https://create.roblox.com/docs/studio/properties#instance-attributes):

- `SkinId`, `ToolTextureId`, and `ToolTip` are now attributes under the pie skin models.
- `EquippedSkinId` is now an attribute under the pie model.
- New attributes `InternalLaunchVelocity` and `InternalPieSpins` under the pie model.
- `CanSwitchType`, `IsClientPieType`, `LaunchOffsetStuds`, `LaunchVelocity`, `NoCollideTransparency`, `PrintDebug`, and `ShowGui` are now attributes under the pie tool.
- New attribute `PieAlignSpin` under the pie tool.
    - This boolean enables the pie's `AlignOrientation`.
    - This needs to be enabled in order for `PieSpinByVelocity` to work.
- Renamed some configurations / attributes:
    - `ClientPie` into `IsClientPieType` attribute under the pie tool.
    - `PieSpins` into `PieSpinByVelocity` attribute under the pie tool.

