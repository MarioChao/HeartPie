# Building the Model

Use [Rojo](https://rojo.space/) to build the model from scratch.

An easy way is to [install Rojo on VS Code](https://rojo.space/docs/v7/getting-started/installation/).

# About the Tool

## Setting up the Tool

The tool requires certain instances to be moved into the containers of the [DataModel](https://create.roblox.com/docs/reference/engine/classes/DataModel).

Open the container scripts (`Heart Pie` > `ContainerScripts (see ReadMe)`) and follow the instructions in `ReadMe`.<br>
When playtesting, there will be warnings in the output if the container scripts aren't correctly set up.

## Reference Properites

The project contains several [reference](https://rojo.space/docs/v7/properties/#ref) properties.<br>
These are dynamically set through the [initializer](/src/Heart%20Pie/ToolScripts/-InitializerActor/Initializer.server.luau) script.

- [ ] SkinMainPart:
    - RigidConstrant (PieSkinAttachment, PieAttachment)
- [ ] MainPart:
    - AlignOrientation (PieAttachment)
    - RigidConstrant (PieRightGripAttachment, RightGripAttachment)
    - UpwardsForce (PieAttachment)

<br>

There may be cases where you want these properties to be set already.<br>
To set these properties in Roblox Studio:

1. Select the pie tool (`Heart Pie`) in studio.
2. Copy & run the [initializer](/src/Heart%20Pie/ToolScripts/-InitializerActor/Initializer.server.luau) script in the command bar.
3. Disable the tool's initializer script, located at (`Heart Pie` > `ToolScripts` > `-InitializerActor` > `Initializer`).

The reason for the additional script is that [Rojo hasn't released full support for Ref properties](https://github.com/rojo-rbx/rojo/blob/7e2bab921aa71f76d07d0424e4bb4064e8b7c995/CHANGELOG.md) at this time.

## Credits

Pie Skins:
- Pumpkin Pi texture from Roblox's [Pumpkin Pi](https://www.roblox.com/catalog/16986805/Pumpkin-Pi) gear.
- Ten-Mou, Moon, Eye, and Stealth Pie textures from VerticalAscent's [Dream Game](https://www.roblox.com/games/5475056496/Dream-Game).
- Heart Pie texture from me.
