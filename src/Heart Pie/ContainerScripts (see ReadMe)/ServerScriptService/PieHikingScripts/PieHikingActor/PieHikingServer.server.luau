--!strict
-- Pie Hiking Server Script

-- ServerScriptService validation check
local function ancestorIsServerScriptService(): boolean
	return script:FindFirstAncestorWhichIsA("ServerScriptService") ~= nil
end
if not ancestorIsServerScriptService() then
	return
end

-- Services
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Variables
local PieHikingEvents = ReplicatedStorage:WaitForChild("PieHikingEvents") :: Folder
local PieHikeRemoteEvent = PieHikingEvents:WaitForChild("PieHikeRemoteEvent") :: RemoteEvent

-- Functions
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

local function runServerHitEffect(caller: Player, throwPieMainPart: Part, hitPart: BasePart)
	-- Validate effect module
	local throwPieModel = throwPieMainPart.Parent :: Model
	local throwPieSkinFolder = throwPieModel and throwPieModel:FindFirstChild("PieSkin")
	local throwPieSkinModel = throwPieSkinFolder and throwPieSkinFolder:FindFirstChildOfClass("Model")
	local pieEffectsConfiguration = throwPieSkinModel and throwPieSkinModel:FindFirstChild("EffectsConfiguration")
	local serverHitEffectModule = pieEffectsConfiguration and pieEffectsConfiguration:FindFirstChild("ServerHitEffect") :: ModuleScript
	if not serverHitEffectModule then
		return
	end
	
	-- Quick validation
	local throwerCharacter = caller.Character
	local throwerHumanoid = throwerCharacter and throwerCharacter:FindFirstChildOfClass("Humanoid")
	local creatorObjectValue = throwPieModel and throwPieModel:FindFirstChild("Creator") :: ObjectValue
	local creator = creatorObjectValue and creatorObjectValue.Value :: Player
	if throwerCharacter ~= creator.Character then
		return
	end
	
	-- Run effect
	local serverHitEffect = require(serverHitEffectModule) :: {[string]: any}
	serverHitEffect.onHit(caller.Character, throwPieMainPart, hitPart)
end

local function stickPiePartToPart(caller: Player, throwPieModel: Model, throwPieMainPart: Part, hitPart: BasePart?, hitCFrame: CFrame, relativeCFrame: CFrame)
	-- Offset main part and stick
	if not hitPart then
		-- Potential actions for sticking Server pies to CSC pies
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
		throwPieMainPart:PivotTo(targetCFrame)
		local weldConstraint = Instance.new("WeldConstraint")
		weldConstraint.Part0 = throwPieMainPart
		weldConstraint.Part1 = hitPart
		weldConstraint.Parent = throwPieMainPart
	end
	
	-- Run hit effect
	if hitPart then
		runServerHitEffect(caller, throwPieMainPart, hitPart)
	end
end

local function stickServerPieToPart(caller: Player, throwPieMainPart: Part?, hitPart: BasePart?, hitCFrame: CFrame, relativeCFrame: CFrame)
	-- Validate parts
	task.desynchronize()
	local throwPieModel = throwPieMainPart and throwPieMainPart.Parent :: Model
	local pieCreatorObject = throwPieModel and throwPieModel:FindFirstChild("Creator") :: ObjectValue
	local pieCreator = pieCreatorObject and pieCreatorObject.Value
	if not (throwPieModel and throwPieMainPart and throwPieMainPart:FindFirstChild("PieAttachment") and throwPieMainPart:IsA("Part")) then
		return
	end
	if caller ~= pieCreator then
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
	stickPiePartToPart(caller, throwPieModel, throwPieMainPart, hitPart, hitPart.CFrame, relativeCFrame)
end

local function stickServerPieToCSCPie(caller: Player, throwPieMainPart: Part?, hitPieId: string, hitCFrame: CFrame, hitSize: Vector3, relativeCFrame: CFrame)
	-- Validate pie
	task.desynchronize()
	local throwPieModel = throwPieMainPart and throwPieMainPart.Parent :: Model
	local pieCreatorObject = throwPieModel and throwPieModel:FindFirstChild("Creator") :: ObjectValue
	local pieCreator = pieCreatorObject and pieCreatorObject.Value
	if not (throwPieModel and throwPieMainPart and throwPieMainPart:FindFirstChild("PieAttachment") and throwPieMainPart:IsA("Part")) then
		return
	end
	if caller ~= pieCreator then
		return
	end

	-- Validate hit location
	local targetCFrame = hitCFrame:ToWorldSpace(relativeCFrame)
	local maxStickDistance = throwPieMainPart.Size.Magnitude + hitSize.Magnitude + 5
	if (targetCFrame.Position - hitCFrame.Position).Magnitude > maxStickDistance then
		return
	end

	-- Stick pie part
	task.synchronize()
	stickPiePartToPart(caller, throwPieModel, throwPieMainPart, nil, hitCFrame, relativeCFrame)
end

local function runHitCharacterEffect(throwerCharacter: Model, hitCharacter: Model, pieMainPart: Part)
	-- Validate effect module
	local pieModel = pieMainPart.Parent :: Model
	local pieSkinFolder = pieModel:FindFirstChild("PieSkin")
	local pieSkinModel = pieSkinFolder and pieSkinFolder:FindFirstChildOfClass("Model")
	local pieEffectsConfiguration = pieSkinModel and pieSkinModel:FindFirstChild("EffectsConfiguration")
	local hitCharacterEffectModule = pieEffectsConfiguration and pieEffectsConfiguration:FindFirstChild("HitCharacterEffect") :: ModuleScript
	if not hitCharacterEffectModule then
		return
	end
	
	-- Quick validation
	local throwerHumanoid = throwerCharacter and throwerCharacter:FindFirstChildOfClass("Humanoid")
	local hitHumanoid = hitCharacter and hitCharacter:FindFirstChildOfClass("Humanoid")
	if not(throwerHumanoid and hitHumanoid) then
		return
	end
	
	-- Run effect
	local hitCharacterEffect = require(hitCharacterEffectModule) :: {[string]: any}
	hitCharacterEffect.onHit(throwerCharacter, hitCharacter, pieMainPart)
end

local function pieHitCharacterEffect(caller: Player, throwerCharacter: Model, hitCharacter: Model, pieMainPart: Part)
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
	if not (caller.Character == throwerCharacter and pieCreator.Character == throwerCharacter and pieMainPart:FindFirstChild("PieAttachment")) then
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

local function unstickServerPie(caller: Player, mainPart: Part?)
	-- Validate pie
	task.desynchronize()
	local pieModel = mainPart and mainPart.Parent
	local pieCreatorObject = pieModel and pieModel:FindFirstChild("Creator") :: ObjectValue
	local pieCreator = pieCreatorObject and pieCreatorObject.Value
	if not (mainPart and mainPart:FindFirstChild("PieAttachment") and caller == pieCreator) then
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

local function removeServerPie(caller: Player, mainPart: Part?)
	-- Validate pie
	task.desynchronize()
	local pieModel = mainPart and mainPart.Parent
	local pieCreatorObject = pieModel and pieModel:FindFirstChild("Creator") :: ObjectValue
	local pieCreator = pieCreatorObject and pieCreatorObject.Value
	if not (mainPart and mainPart:FindFirstChild("PieAttachment") and caller == pieCreator) then
		return
	end
	
	-- Remove pie
	Debris:AddItem(pieModel, 0)
end

-- Event functions
local function onPieHikeServerEvent(player: Player, mode: string, ...)
	if mode == "Stick Server Pie To Part" then
		stickServerPieToPart(player, ...)
	elseif mode == "Stick Server Pie To CSC Pie" then
		stickServerPieToCSCPie(player, ...)
	elseif mode == "Pie Hit Character Effect" then
		pieHitCharacterEffect(player, ...)
	elseif mode == "Unstick" then
		unstickServerPie(player, ...)
	elseif mode == "Remove" then
		removeServerPie(player, ...)
	end
end

-- Calling / connecting functions
PieHikeRemoteEvent.OnServerEvent:Connect(onPieHikeServerEvent)
