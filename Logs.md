# Changelog and Plans

## Plans

- Improve how skins are unlocked.

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

