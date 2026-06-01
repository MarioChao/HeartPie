--!strict

-- Pie Hit Effects Getter


---------- Imports ----------

local _Presets = script.Parent:WaitForChild("Presets")
local PieHitEffects = (function()
	-- Import default
	local DefaultHitEffects = require(_Presets:WaitForChild("DefaultHitEffects"))

	-- Attempt to import & return custom
	local _CustomHitEffectsObjectValue = _Presets:WaitForChild("CustomHitEffectsObjectValue")
	if _CustomHitEffectsObjectValue.Value then
		local pcallSuccess, CustomHitEffects = pcall(function()
			return require(_CustomHitEffectsObjectValue.Value) :: typeof(DefaultHitEffects)
		end)
		if pcallSuccess then
			return CustomHitEffects
		end
	end

	-- Return default
	return DefaultHitEffects
end)()


---------- Types ----------

export type EffectParameter = {
	throwerCharacter: Model,
	hitCharacter: Model?,
	pieMainPart: Part,
	hitPart: BasePart?,
}

type EffectFunction = (param: EffectParameter) -> ()

type EffectInfo = {
	ServerHit: EffectFunction?,
	ClientHit: EffectFunction?,
	ClientUseServer: boolean,
	HitCharacter: EffectFunction?,
}


---------- Module ----------

local Module = {}


----- Module fields -----

function Module.getValueAt(name: string)
	return PieHitEffects[name]
end

function Module.getTable()
	return PieHitEffects
end


---------- Return module ----------

table.freeze(Module)
return Module
