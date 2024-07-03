--!strict
-- Client Hit Effect ModuleScript

-- Variables
local EffectsListModule = script.Parent.Parent.Parent:FindFirstChild("EffectsList")
local EffectsList = require(EffectsListModule)

-- Functions
local function runHitEffect(throwerCharacter: Model, pieMainPart: Part, hitPart: BasePart)
	-- Modify this function to configure hit effects
	EffectsList.orbEffectAtPart(pieMainPart, Color3.new(1, 0.54, 0.78), {0, 0}, {8, 4}, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
end

---------- Module ----------
local hitEffect = {}

-- Functions
function hitEffect.onHit(throwerCharacter: Model, pieMainPart: Part, hitPart: BasePart)
	-- Run effect
	runHitEffect(throwerCharacter, pieMainPart, hitPart)
end

return hitEffect
