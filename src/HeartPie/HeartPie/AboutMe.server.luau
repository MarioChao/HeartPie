--[[


---------- Customizing pie skins ----------

----- Pie skins -----

Both starter pie skins (unlocked by default) and conditional pie skins (like Badge skins) are configured through
`ServerScriptService / PieHiking_ServerScripts / SkinModules`.


----- Sounds -----

Customize sounds through `ReplicatedStorage / PieHiking_SharedStorage / SoundModules`.


---------- Customizing pie trajectory ----------

----- Beginner pie -----

A beginner pie doesn't have a launching offset, but you can't jump on them mid-air.

For beginner pie, set these attributes on the tool config (`HeartPie / ToolValues / ToolConfig`):

- CanCollideThrower: false
- LaunchOffsetStuds: 0
- LaunchVelocity: 95

These values are similar to drumpiece's beginner pie found in Postmortem.


----- Classic pie -----

A classic pie has a 10 studs launching offset, but you can do mid-air pie jumps (client pie type only).

For classic pie, set these attributes on the tool config (`HeartPie / ToolValues / ToolConfig`):

- CanCollideThrower: true
- LaunchOffsetStuds: 10
- LaunchVelocity: 50


----- Unstick & remove time -----

You can customize pie unstick & remove delay through `HeartPie / PieModel / PieValues / PieConfig`.


]]