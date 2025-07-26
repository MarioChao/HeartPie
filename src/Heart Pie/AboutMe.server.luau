--[[


---------- Customizing pie appearance ----------

----- Pie skins -----

Default pie skins should be placed in the `PieSkins` folder under the tool.

Conditional skins (like Badge skins) should be placed in `ServerStorage` > `PieHikingServerStorage` > `PieSkins`.


----- Sounds -----

Change the SoundId of the sounds under `PieModel` > `MainPart`.



---------- Customizing pie trajectory ----------

----- Beginner pie -----

A beginner pie doesn't have a launching offset, but you can't jump on them mid-air.

For beginner pie, set these attributes on the pie tool:

- CanCollideThrower: false
- LaunchOffsetStuds: 0
- LaunchVelocity: 95

These values are similar to drumpiece's beginner pie found in Postmortem.


----- Regular pie -----

A regular pie has a 10 studs launching offset, but you can do mid-air pie jumps (client pie type only).

For regular pie, set these attributes on the pie tool:

- CanCollideThrower: true
- LaunchOffsetStuds: 10
- LaunchVelocity: 50


]]