--!strict
-- Client Hit Effect ModuleScript

-- Variables
local EffectsListModule = script.Parent.Parent.Parent:FindFirstChild("EffectsList")
local EffectsList = require(EffectsListModule)

-- Functions
local function runHitEffect(throwerCharacter: Model, pieMainPart: Part, hitPart: BasePart)
	-- Modify this function to configure hit effects
	EffectsList.orbEffectAtPart(pieMainPart, Color3.new(0.42, 0.76, 0.95), {0, 0}, {4, 8}, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
end

---------- Module ----------
local hitEffect = {}

-- Functions
function hitEffect.onHit(throwerCharacter: Model, pieMainPart: Part, hitPart: BasePart)
	-- Run effect
	runHitEffect(throwerCharacter, pieMainPart, hitPart)
end

return hitEffect
