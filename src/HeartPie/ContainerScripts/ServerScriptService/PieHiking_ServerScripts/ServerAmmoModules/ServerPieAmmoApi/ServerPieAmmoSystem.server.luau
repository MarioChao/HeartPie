--!strict

-- Server Pie Ammo System


---------- Validate container ----------

-- Server script service
if not script:FindFirstAncestorWhichIsA("ServerScriptService") then
	return
end


---------- Services ----------

local ReplicatedStorage = game:GetService("ReplicatedStorage")


---------- Imports ----------

local _PieHiking_SharedStorage = ReplicatedStorage:WaitForChild("PieHiking_SharedStorage")
local _EffectModules = _PieHiking_SharedStorage:WaitForChild("EffectModules")
local PieHitEffectsGetter = require(_EffectModules:WaitForChild("PieHitEffectsGetter"))

local _AmmoModules = _PieHiking_SharedStorage:WaitForChild("AmmoModules")
local AmmoUtil = require(_AmmoModules:WaitForChild("AmmoUtil"))


---------- Constants ----------

local Constants = {}

Constants.apiBindableEvent = script.Parent:WaitForChild("ApiBindableEvent")

table.freeze(Constants)


---------- Local functions ----------

local runServerHitEffect
local stickPiePartToPart
local stickServerPieToPart

local _runHitCharacterEffect
local runPieHitCharacterEffectProxy

local unstickServerPie
local removeServerPie


----- Stick -----

runServerHitEffect = function(throwPieMainPart: BasePart, hitPart: BasePart)
	-- Validate creator
	local throwPieModel = throwPieMainPart.Parent
	if not (throwPieModel and throwPieModel:IsA("Model")) then
		return
	end
	local creatorObjectValue = throwPieModel and throwPieModel:FindFirstChild("Creator")
	if not (creatorObjectValue and creatorObjectValue:IsA("ObjectValue")) then
		return
	end
	local creator = creatorObjectValue and creatorObjectValue.Value
	if not (creator and creator:IsA("Player")) then
		return
	end
	local throwerCharacter = creator and creator.Character
	if not throwerCharacter then
		return
	end

	-- Get parameters
	local param: PieHitEffectsGetter.EffectParameter = {
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
	local effectInfo = PieHitEffectsGetter.getValueAt(throwPieSkinModel.Name)
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

stickPiePartToPart = function(throwPieModel: Model, throwPieMainPart: BasePart, hitPart: BasePart?, hitCFrame: CFrame, relativeCFrame: CFrame)
	-- Offset main part and stick
	if not hitPart then
		-- Potential actions for sticking Server pies to client parts
	end

	-- Disable forces and align orientation
	local upwardsForce = throwPieMainPart:FindFirstChild("UpwardsForce")
	if upwardsForce and upwardsForce:IsA("VectorForce") then
		upwardsForce.Enabled = false
	else
		warn(`[Server Pie Ammo System]: No upwards force found for pie model.`)
	end
	local alignOrientation = throwPieMainPart:FindFirstChild("AlignOrientation")
	if alignOrientation and alignOrientation:IsA("AlignOrientation") then
		alignOrientation.Enabled = false
	else
		warn(`[Server Pie Ammo System]: No align orientation found for pie model.`)
	end

	if hitPart then
		-- Stick to Server part
		local targetCFrame = hitPart.CFrame:ToWorldSpace(relativeCFrame)
		AmmoUtil.setPieCollision(throwPieModel, false)
		throwPieMainPart:PivotTo(targetCFrame)
		local weldConstraint = Instance.new("WeldConstraint")
		weldConstraint.Part0 = throwPieMainPart
		weldConstraint.Part1 = hitPart
		weldConstraint.Parent = throwPieMainPart
		AmmoUtil.setPieCollision(throwPieModel)
	end

	-- Run hit effect
	if hitPart then
		runServerHitEffect(throwPieMainPart, hitPart)
	end
end

stickServerPieToPart = function(throwPieMainPart: BasePart?, hitPart: BasePart?, hitCFrame: CFrame, relativeCFrame: CFrame)
	-- Validate parts
	local throwPieModel = throwPieMainPart and throwPieMainPart.Parent
	if not (throwPieModel and throwPieModel:IsA("Model")) then
		return
	end
	if not (throwPieMainPart and throwPieMainPart:FindFirstChild("PieAttachment") and throwPieMainPart:IsA("BasePart")) then
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
	stickPiePartToPart(throwPieModel, throwPieMainPart, hitPart, hitPart.CFrame, relativeCFrame)
end


----- Hit character effect -----

_runHitCharacterEffect = function(throwerCharacter: Model, hitCharacter: Model, pieMainPart: BasePart)
	-- Quick validation
	local throwerHumanoid = throwerCharacter and throwerCharacter:FindFirstChildOfClass("Humanoid")
	local hitHumanoid = hitCharacter and hitCharacter:FindFirstChildOfClass("Humanoid")
	if not (throwerHumanoid and hitHumanoid) then
		return
	end

	-- Get parameters
	local param: PieHitEffectsGetter.EffectParameter = {
		throwerCharacter = throwerCharacter,
		hitCharacter = hitCharacter,
		pieMainPart = pieMainPart,
		hitPart = nil,
	}

	-- Get effect function
	local pieModel = pieMainPart.Parent
	local pieSkinFolder = pieModel and pieModel:FindFirstChild("PieSkin")
	local pieSkinModel = pieSkinFolder and pieSkinFolder:FindFirstChildOfClass("Model")
	if not pieSkinModel then
		return
	end
	local effectInfo = PieHitEffectsGetter.getValueAt(pieSkinModel.Name)
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

runPieHitCharacterEffectProxy = function(throwerCharacter: Model, hitCharacter: Model, pieMainPart: BasePart)
	-- Stick should be called already, so wait a frame for that to happen
	task.wait()

	-- Get humanoid root part
	local humanoidRootPart = hitCharacter and hitCharacter:FindFirstChild("HumanoidRootPart") :: Part

	-- Get pie info
	local pieModel = pieMainPart.Parent
	local pieCreatorObject = pieModel and pieModel:FindFirstChild("Creator")
	local pieCreator = (pieCreatorObject and pieCreatorObject:IsA("ObjectValue") and pieCreatorObject.Value) or nil
	local pieWeldConstraint= pieMainPart and pieMainPart:FindFirstChild("WeldConstraint")
	local pieWeldPart = (pieWeldConstraint and pieWeldConstraint:IsA("WeldConstraint") and pieWeldConstraint.Part1) or nil

	-- Validate pie
	if not (
		pieModel and pieModel:IsA("Model")
		and pieMainPart and pieCreator and humanoidRootPart
		and pieCreator:IsA("Player") and pieCreator.Character == throwerCharacter
		and pieMainPart:FindFirstChild("PieAttachment")
		and pieWeldPart and humanoidRootPart.AssemblyRootPart == pieWeldPart.AssemblyRootPart
	) then
		warn(`[Server Pie Ammo System]: Invalid pie detected.`)
		return
	end

	-- Check can hit
	if not AmmoUtil.checkCanHitCharacter(throwerCharacter, hitCharacter) then
		return
	end

	-- Ensure effect only runs once
	local hasHit = pieModel:FindFirstChild("HasHit")
	if hasHit and hasHit:IsA("BoolValue") and hasHit.Value then
		return
	end
	if not hasHit then
		local newHasHit = Instance.new("BoolValue")
		newHasHit.Name = "HasHit"
		newHasHit.Value = true
		newHasHit.Parent = pieModel
	elseif hasHit:IsA("BoolValue") then
		hasHit.Value = true
	end

	-- Run hit character effect
	_runHitCharacterEffect(throwerCharacter, hitCharacter, pieMainPart)
end


----- Remove & unstick -----

unstickServerPie = function(mainPart: BasePart)
	-- Validate pie
	if not (mainPart and mainPart:FindFirstChild("PieAttachment")) then
		return
	end

	-- Unstick pie
	for _, instance in mainPart:GetChildren() do
		if instance:IsA("WeldConstraint") and instance.Enabled then
			instance.Enabled = false
		end
	end
end

removeServerPie = function(mainPart: BasePart)
	-- Validate pie
	if not (mainPart and mainPart:FindFirstChild("PieAttachment")) then
		return
	end

	-- Remove pie
	local pieModel = mainPart and mainPart.Parent
	if pieModel then
		pieModel:Destroy()
	end
end


----- Main -----

local function main()
	Constants.apiBindableEvent.Event:Connect(function(mode: string, ...)
		if mode == "Stick Server Pie to Part" then
			stickServerPieToPart(...)
		elseif mode == "Run Pie Hit Character Effect" then
			runPieHitCharacterEffectProxy(...)
		elseif mode == "Unstick" then
			unstickServerPie(...)
		elseif mode == "Remove" then
			removeServerPie(...)
		end
	end)
end


---------- Calling function ----------

main()
