--!strict

-- Sound Effects Getter


---------- Imports ----------

local _Presets = script.Parent:WaitForChild("Presets")
local SoundEffects = (function()
	-- Import default
	local DefaultSoundEffects = require(_Presets:WaitForChild("DefaultSoundEffects"))

	-- Attempt to import & return custom
	local _CustomSoundEffectsObjectValue = _Presets:WaitForChild("CustomSoundEffectsObjectValue")
	if _CustomSoundEffectsObjectValue.Value then
		local pcallSuccess, CustomSoundEffects = pcall(function()
			return require(_CustomSoundEffectsObjectValue.Value) :: typeof(DefaultSoundEffects)
		end)
		if pcallSuccess then
			return CustomSoundEffects
		end
	end

	-- Return default
	return DefaultSoundEffects
end)()


---------- Types ----------

export type SoundEffectNames = "fire" | "hit"


---------- Module ----------

local Module = {}


----- Module fields -----

function Module.getValueAt(name: string)
	return SoundEffects.skinSounds[name] or SoundEffects.default
end

function Module.getTable()
	return SoundEffects
end


---------- Return module ----------

table.freeze(Module)
return Module
