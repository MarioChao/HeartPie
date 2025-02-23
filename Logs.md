# Changelog and Plans

## Plans

- [+] Allow pies to be visible if they are initially in the workspace.

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

