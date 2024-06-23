--!strict
-- Hit Character Effect ModuleScript

-- Variables
local EffectsListModule = script.Parent.Parent.Parent:FindFirstChild("EffectsList")
local EffectsList = require(EffectsListModule)

-- Functions
local function runHitCharacterEffect(throwerCharacter: Model, hitCharacter: Model, pieMainPart: Part)
	-- Modify this function to configure hit character effects
	EffectsList.damageCharacter(hitCharacter, 5)
end

---------- Module ----------
local hitCharacterEffect = {}

-- Functions
function hitCharacterEffect.onHit(throwerCharacter: Model, hitCharacter: Model, pieMainPart: Part)
	-- Run effect
	runHitCharacterEffect(throwerCharacter, hitCharacter, pieMainPart)
end

return hitCharacterEffect
