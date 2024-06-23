--!strict
-- Effects Module Script

-- Services
local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

---------- Module ----------
local effectsList = {}

-- Effect functions
function effectsList.damageCharacter(character: Model, amount: number)
	-- Validate
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not (humanoid and humanoid.Health > 0 and tonumber(amount)) then
		return
	end

	-- Damage
	humanoid:TakeDamage(amount)
end

function effectsList.changeHealth(character: Model, amount: number)
	-- Validate
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not (humanoid and humanoid.Health > 0 and tonumber(amount)) then
		return
	end

	-- Change health
	humanoid.Health += amount
end

function effectsList.addTagToCharacterHumanoid(character: Model, tag: string)
	-- Validate
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	-- Add a tag to humanoid
	CollectionService:AddTag(humanoid, tag)
end

function effectsList.removeTagFromCharacterHumanoid(character: Model, tag: string)
	-- Validate
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	-- Remove a tag from humanoid
	CollectionService:RemoveTag(humanoid, tag)
end

function effectsList.orbEffectAtPart(part: BasePart, orbColor: Color3, initialOrbSizes: {number}, targetOrbSizes: {number}, easingStyle: Enum.EasingStyle, easingDirection: Enum.EasingDirection)
	-- Validate
	if not (part and part:IsA("BasePart")) then
		return
	end

	-- Effect
	local defaultOrbPart = Instance.new("Part")
	defaultOrbPart.Color = orbColor
	defaultOrbPart.Transparency = 0.6
	defaultOrbPart.CFrame = part.CFrame
	defaultOrbPart.CanCollide = false
	defaultOrbPart.CanTouch = false
	defaultOrbPart.CanQuery = false
	defaultOrbPart.Anchored = true
	defaultOrbPart.Shape = Enum.PartType.Ball
	defaultOrbPart.TopSurface = Enum.SurfaceType.Smooth
	defaultOrbPart.BottomSurface = Enum.SurfaceType.Smooth
	local orbTweenInfo = TweenInfo.new(0.5, easingStyle, easingDirection, 0, false)

	for i = 1, math.min(#initialOrbSizes, #targetOrbSizes) do
		task.defer(function()
			-- Get sizes
			local initialSize = Vector3.one * initialOrbSizes[i]
			local targetSize = Vector3.one * targetOrbSizes[i]
			
			-- Create part in workspace
			local orbPart = defaultOrbPart:Clone()
			orbPart.Size = initialSize
			orbPart.Parent = workspace

			-- Tween
			local tween = TweenService:Create(orbPart, orbTweenInfo, {["Size"] = targetSize, ["Transparency"] = 1})
			tween:Play()

			-- Remove part
			tween.Completed:Wait()
			Debris:AddItem(orbPart, 0)
		end)
	end
end

-- Template effect functions
function effectsList.customEffectAtCharacter(character: Model)
	-- Validate
	local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart") :: Part
	if not humanoidRootPart then
		return
	end

	-- Effect

end

function effectsList.customEffectAtPart(part: BasePart)
	-- Validate
	if not (part and part:IsA("BasePart")) then
		return
	end

	-- Effect

end

return effectsList
