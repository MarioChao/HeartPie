# Heart Pie

## Setting up the Tool

The tool requires certain instances to be moved into the containers of the [DataModel](https://create.roblox.com/docs/reference/engine/classes/DataModel).

Open the container scripts (`src / HeartPie / ContainerScripts`) and follow the instructions in `ReadMe`.

You can also require the module script (`src / HeartPieModule / MainModule`).

> [!TIP]
>
> You can also set up the tool using the [Pie Hiking Creation Kit](https://create.roblox.com/store/asset/18723187294/Pie-Hiking-Creation-Kit) plugin,
> which also contains a kit for creating pie hiking maps!

## Reference Properites

The project contains several [reference](https://rojo.space/docs/v7/properties/#ref) properties.<br>
These are dynamically set through the [initializer](/src/HeartPie/HeartPie/ToolScripts/ToolInitializer.server.luau) and [PieSkins](/src/HeartPie/HeartPie/ToolScripts/PieSkins/ServerPieSkin.server.luau) script.

- `SkinMainPart`:
    - RigidConstrant (PieSkinAttachment, PieAttachment)
- `MainPart`:
    - AlignOrientation (PieAttachment)
    - RigidConstrant (PieRightGripAttachment, RightGripAttachment)
    - UpwardsForce (PieAttachment)

<br>

There may be cases where you want these properties to be set already.<br>
To set these properties in Roblox Studio:

1. Select the pie tool (`Heart Pie`) in studio.
2. Copy & run the [initializer](/src/HeartPie/HeartPie/ToolScripts/ToolInitializer.server.luau) script in the command bar.

## Credits

Pie Skins:
- Pumpkin Pi texture from Roblox's [Pumpkin Pi](https://www.roblox.com/catalog/16986805/Pumpkin-Pi) gear.
- Ten-Mou, Moon, Eye, and Stealth Pie textures from VerticalAscent's [Dream Game](https://www.roblox.com/games/5475056496/Dream-Game).
- Heart Pie texture from me.
