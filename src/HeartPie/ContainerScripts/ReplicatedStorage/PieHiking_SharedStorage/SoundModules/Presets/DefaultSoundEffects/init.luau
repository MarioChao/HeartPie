--!strict

-- Default Sound Effects


---------- Types ----------

type PieSoundEffects = {
	fire: Sound,
	hit: Sound,
}


---------- Imports ----------

local _Sounds = script:WaitForChild("Sounds")


---------- Sound effect modules ----------

local DefaultSound: PieSoundEffects
local SkinSounds: {[string]: PieSoundEffects} = {}


----- Default sound effect -----

DefaultSound = {
	fire = _Sounds:WaitForChild("DefaultFireSound"),
	hit = _Sounds:WaitForChild("DefaultHitSound"),
}


----- Sound effects -----

SkinSounds["Heart"] = {
	fire = _Sounds:WaitForChild("CuteFireSound"),
	hit = _Sounds:WaitForChild("CuteHitSound"),
}



---------- Module ----------

local Module = {}


----- Module fields -----

Module.default = DefaultSound
Module.skinSounds = SkinSounds


---------- Return module ----------

table.freeze(Module)
return Module
