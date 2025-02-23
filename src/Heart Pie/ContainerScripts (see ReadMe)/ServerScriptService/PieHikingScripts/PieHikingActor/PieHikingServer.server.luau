--!strict
-- Pie Hiking Server Script

---------- Validate container ----------
-- Validate the script's container before running any code

-- For some server scripts
if not script:FindFirstAncestorWhichIsA("ServerScriptService") then
	return
end

---------- Services ----------

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage") or script.Parent.Parent.Parent.Parent.ReplicatedStorage

---------- Imports ----------

local PieHikingModules = ReplicatedStorage:WaitForChild("PieHikingModules")
local PieHitEffects = require(PieHikingModules:WaitForChild("PieHitEffects"))

---------- Variables ----------

local PieHikingEvents = ReplicatedStorage:WaitForChild("PieHikingEvents") :: Folder
local PieHikeBindable = PieHikingEvents:WaitForChild("PieHikeBindable") :: BindableEvent
local PieHikeRemoteEvent = PieHikingEvents:WaitForChild("PieHikeRemoteEvent") :: RemoteEvent

---------- Local functions ----------

-- Nil for originalCanCollide
local function setPieCollision(pieModel: Model, canCollide: boolean?)
	for _, part in pieModel:GetDescendants() do
		if part:IsA("BasePart") then
			-- Collision
			if canCollide == nil then
				local originalCanCollide = part:FindFirstChild("OriginalCanCollide") :: BoolValue
				if originalCanCollide then
					part.CanCollide = originalCanCollide.Value
				end
			else
				part.CanCollide = canCollide
			end
		end
	end
end

-- Pie hike functions
local function checkCanHitCharacter(characterThrow: Model?, characterHit: Model?): boolean
	-- Check existence
	if not (characterThrow and characterHit) then
		return false
	end

	-- Check for hitting enemy npc
	local hitHumanoid = characterHit:FindFirstChildOfClass("Humanoid")
	if not hitHumanoid then
		return false
	end
	if hitHumanoid.Name == "Path" then
		-- (Enemy NPCs of Dream Game)
		return true
	end

	-- Check for pvp value
	if characterThrow:FindFirstChild("pvp") and characterHit:FindFirstChild("pvp") then
		return true
	end

	return false
end

local function runServerHitEffect(throwPieMainPart: Part, hitPart: BasePart)
	-- Validate creator
	local throwPieModel = throwPieMainPart.Parent :: Model
	local creatorObjectValue = throwPieModel and throwPieModel:FindFirstChild("Creator") :: ObjectValue
	local creator = creatorObjectValue and creatorObjectValue.Value :: Player
	local throwerCharacter = creator and creator.Character
	if not throwerCharacter then
		return
	end

	-- Get parameters
	local param: PieHitEffects.EffectParameter = {
		throwerCharacter = throwerCharacter,
		hitCharacter = nil,
		pieMainPart = throwPieMainPart,
		hitPart = hitPart,
	}

	-- Get effect function
	local throwPieSkinFolder = throwPieModel and throwPieModel:FindFirstChild("PieSkin")
	local throwPieSkinModel = throwPieSkinFolder and throwPieSkinFolder:FindFirstChildOfClass("Model")
	if not throwPieSkinModel then
		return
	end
	local effectInfo = PieHitEffects[throwPieSkinModel.Name]
	if not effectInfo then
		return
	end
	local effectFunction = effectInfo.ServerHit
	if not effectFunction then
		return
	end

	-- Run effect
	effectFunction(param)
end

local function stickPiePartToPart(throwPieModel: Model, throwPieMainPart: Part, hitPart: BasePart?, hitCFrame: CFrame, relativeCFrame: CFrame)
	-- Offset main part and stick
	if not hitPart then
		-- Potential actions for sticking Server pies to client parts
	end

	-- Disable forces and align orientation
	local upwardsForce = throwPieMainPart:FindFirstChild("UpwardsForce") :: VectorForce
	if upwardsForce then
		upwardsForce.Enabled = false
	end
	local alignOrientation = throwPieMainPart:FindFirstChild("AlignOrientation") :: AlignOrientation
	if alignOrientation then
		alignOrientation.Enabled = false
	end

	if hitPart then
		-- Stick to Server part
		local targetCFrame = hitPart.CFrame:ToWorldSpace(relativeCFrame)
		setPieCollision(throwPieModel, false)
		throwPieMainPart:PivotTo(targetCFrame)
		local weldConstraint = Instance.new("WeldConstraint")
		weldConstraint.Part0 = throwPieMainPart
		weldConstraint.Part1 = hitPart
		weldConstraint.Parent = throwPieMainPart
		setPieCollision(throwPieModel)
	end

	-- Run hit effect
	if hitPart then
		runServerHitEffect(throwPieMainPart, hitPart)
	end
end

local function stickServerPieToPart(throwPieMainPart: Part?, hitPart: BasePart?, hitCFrame: CFrame, relativeCFrame: CFrame)
	-- Validate parts
	task.desynchronize()
	local throwPieModel = throwPieMainPart and throwPieMainPart.Parent :: Model
	local pieCreatorObject = throwPieModel and throwPieModel:FindFirstChild("Creator") :: ObjectValue
	local pieCreator = pieCreatorObject and pieCreatorObject.Value
	if not (throwPieModel and throwPieMainPart and throwPieMainPart:FindFirstChild("PieAttachment") and throwPieMainPart:IsA("Part")) then
		return
	end
	if not (hitPart and hitPart:IsA("BasePart")) then
		return
	end

	-- Validate hit part
	local targetCFrame = hitPart.CFrame:ToWorldSpace(relativeCFrame)
	local maxStickDistance = throwPieMainPart.Size.Magnitude + hitPart.Size.Magnitude + 5
	if (targetCFrame.Position - hitPart.Position).Magnitude > maxStickDistance then
		return
	end

	-- Stick pie part
	task.synchronize()
	stickPiePartToPart(throwPieModel, throwPieMainPart, hitPart, hitPart.CFrame, relativeCFrame)
end

local function runHitCharacterEffect(throwerCharacter: Model, hitCharacter: Model, pieMainPart: Part)
	-- Quick validation
	local throwerHumanoid = throwerCharacter and throwerCharacter:FindFirstChildOfClass("Humanoid")
	local hitHumanoid = hitCharacter and hitCharacter:FindFirstChildOfClass("Humanoid")
	if not (throwerHumanoid and hitHumanoid) then
		return
	end

	-- Get parameters
	local param: PieHitEffects.EffectParameter = {
		throwerCharacter = throwerCharacter,
		hitCharacter = hitCharacter,
		pieMainPart = pieMainPart,
		hitPart = nil,
	}

	-- Get effect function
	local pieModel = pieMainPart.Parent :: Model
	local pieSkinFolder = pieModel:FindFirstChild("PieSkin")
	local pieSkinModel = pieSkinFolder and pieSkinFolder:FindFirstChildOfClass("Model")
	if not pieSkinModel then
		return
	end
	local effectInfo = PieHitEffects[pieSkinModel.Name]
	if not effectInfo then
		return
	end
	local effectFunction = effectInfo.HitCharacter
	if not effectFunction then
		return
	end

	-- Run effect
	effectFunction(param)
end

local function pieHitCharacterEffect(throwerCharacter: Model, hitCharacter: Model, pieMainPart: Part)
	-- Stick should be called already, so wait a frame for that to happen
	task.desynchronize()
	task.wait(0.03)

	-- Get humanoid root part
	local humanoidRootPart = hitCharacter and hitCharacter:FindFirstChild("HumanoidRootPart") :: Part

	-- Get pie info
	local pieModel = pieMainPart.Parent :: Model
	local pieCreatorObject = pieModel and pieModel:FindFirstChild("Creator") :: ObjectValue
	local pieCreator = pieCreatorObject and pieCreatorObject.Value :: Player
	local pieWeldConstraint= pieMainPart and pieMainPart:FindFirstChild("WeldConstraint") :: WeldConstraint
	local pieWeldPart = pieWeldConstraint and pieWeldConstraint.Part1

	-- Validate hit
	if not (pieMainPart and pieCreator and humanoidRootPart) then
		return
	end
	if not (pieCreator.Character == throwerCharacter and pieMainPart:FindFirstChild("PieAttachment")) then
		return
	end
	if not (pieWeldPart and humanoidRootPart.AssemblyRootPart == pieWeldPart.AssemblyRootPart) then
		return
	end
	if not checkCanHitCharacter(throwerCharacter, hitCharacter) then
		return
	end

	-- Ensure effect only runs once
	local hasHit = pieModel:FindFirstChild("HasHit") :: BoolValue
	if hasHit and hasHit.Value then
		return
	end
	task.synchronize()
	if not hasHit then
		local newHasHit = Instance.new("BoolValue")
		newHasHit.Name = "HasHit"
		newHasHit.Value = true
		newHasHit.Parent = pieModel
	else
		hasHit.Value = true
	end

	-- Run hit character effect
	runHitCharacterEffect(throwerCharacter, hitCharacter, pieMainPart)
end

local function unstickServerPie(mainPart: Part?)
	-- Validate pie
	task.desynchronize()
	if not (mainPart and mainPart:FindFirstChild("PieAttachment")) then
		return
	end

	-- Unstick pie
	task.synchronize()
	for _, instance in mainPart:GetChildren() do
		if instance:IsA("WeldConstraint") and instance.Enabled then
			instance.Enabled = false
		end
	end
end

local function removeServerPie(mainPart: Part?)
	-- Validate pie
	task.desynchronize()
	local pieModel = mainPart and mainPart.Parent
	if not (mainPart and mainPart:FindFirstChild("PieAttachment")) then
		return
	end

	-- Remove pie
	Debris:AddItem(pieModel, 0)
end

---------- Event functions ----------

local function onPieHikeBindableEvent(mode: string, ...)
	if mode == "Stick Server Pie To Part" then
		stickServerPieToPart(...)
	elseif mode == "Pie Hit Character Effect" then
		pieHitCharacterEffect(...)
	elseif mode == "Unstick" then
		unstickServerPie(...)
	elseif mode == "Remove" then
		removeServerPie(...)
	end
end

---------- Calling / connecting functions ----------

PieHikeBindable.Event:Connect(onPieHikeBindableEvent)
