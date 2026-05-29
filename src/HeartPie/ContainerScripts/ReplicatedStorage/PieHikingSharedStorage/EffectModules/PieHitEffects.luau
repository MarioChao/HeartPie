--!strict

-- Pie Hit Effects


---------- Imports ----------

local _Presets = script.Parent:WaitForChild("Presets")
local DefaultPieHitEffects = require(_Presets:WaitForChild("DefaultHitEffects"))
local PieHitEffects = (function()
	local _CustomHitEffectsObjectValue = _Presets:WaitForChild("CustomHitEffectsObjectValue")
	if _CustomHitEffectsObjectValue.Value then
		local pcallSuccess, CustomHitEffects = pcall(function()
			return require(_CustomHitEffectsObjectValue.Value) :: typeof(DefaultPieHitEffects)
		end)
		if pcallSuccess then
			return CustomHitEffects
		end
	end
	return DefaultPieHitEffects
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


---------- Return module ----------

if not table.isfrozen(PieHitEffects) then
    table.freeze(PieHitEffects)
end
return PieHitEffects
