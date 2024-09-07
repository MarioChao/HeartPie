--!strict
-- Client-Server-Client Pie Ammo Script
-- Creates & launches client pies fired by other players

---------- Validate container ----------
-- Validate the script's container before running any code

-- For certain client scripts
if not script:FindFirstAncestorWhichIsA("PlayerScripts") then
	return
end

---------- Services ----------

local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

---------- Imports ----------

local CSCPieMotionActor = script.Parent
local CSCPieAmmo = require(CSCPieMotionActor:WaitForChild("CSCPieAmmoModule"))

---------- Variables ----------

local PieHikingEvents = ReplicatedStorage:WaitForChild("PieHikingEvents") :: Folder
local CSCPieRemoteEvent = PieHikingEvents:WaitForChild("CSCPieRemoteEvent") :: RemoteEvent

type FinalizedMotion = {["CFrame"]: CFrame?, ["Direction"]: Vector3?, ["Velocity"]: number?}
type SpinInfo = {["AlignSpin"]: boolean?, ["ByVelocity"]: boolean?}

---------- Local functions ----------

-- Launch functions
local function newAmmo(ammoModel: Model)
	if not ammoModel:IsA("Model") then
		return
	end
	local ammo = CSCPieAmmo.new(ammoModel, false)
	ammo:launchPie()
end

local function getPieAmmoModel(pieModel: Model, canCollide: boolean, noCollideTransparency: number): Model
	-- Clone the pie model
	local pieAmmoModel = pieModel:Clone()
	local pieAmmoMainPart = pieAmmoModel:FindFirstChild("MainPart") :: Part
	local pieAttachment = pieAmmoMainPart:FindFirstChild("PieAttachment") :: Attachment
	local rigidConstraint = pieAmmoMainPart and pieAmmoMainPart:FindFirstChild("RigidConstraint") :: RigidConstraint
	local upwardsForce = pieAmmoMainPart and pieAmmoMainPart:FindFirstChild("UpwardsForce") :: VectorForce

	-- Set up objects
	for _, part in pieAmmoModel:GetDescendants() do
		if part:IsA("BasePart") then
			-- Transparency
			local originalTransparency = part:FindFirstChild("OriginalTransparency") :: NumberValue
			local newTransparency: number
			if originalTransparency then
				newTransparency = originalTransparency.Value
			else
				newTransparency = part.Transparency
			end

			part.Transparency = newTransparency

			-- No collide transparency
			if not canCollide then
				part.LocalTransparencyModifier = noCollideTransparency
			end

			-- Collisions
			if part:IsA("BasePart") then
				-- Collision & touch
				part.CanCollide = false
				part.CanTouch = false
				part.CanQuery = false
			end
		elseif part:IsA("Decal") then
			-- Transparency
			local originalTransparency = part:FindFirstChild("OriginalTransparency") :: NumberValue
			local newTransparency: number
			if originalTransparency then
				newTransparency = originalTransparency.Value
			else
				newTransparency = part.Transparency
			end

			part.Transparency = newTransparency

			-- No collide transparency
			if not canCollide then
				part.LocalTransparencyModifier = noCollideTransparency
			end
		end
	end
	if rigidConstraint then
		rigidConstraint.Enabled = false
		-- Notice: the constraint might connect to the original tool's Handle
	end
	if upwardsForce then
		upwardsForce.Enabled = true
	end

	return pieAmmoModel
end

local function onLaunchCSCPie(creatorPlayer: Player, launchMotion: FinalizedMotion, canCollide: boolean, noCollideTransparency: number, clientPieId: string, pieModel: Model, pieSpinInfo: SpinInfo)
	-- Validate pie info
	if not (pieModel and pieModel.Parent and typeof(clientPieId) == "string") then
		return
	end

	-- Get launch motion
	local launchCFrame = launchMotion.CFrame :: CFrame
	local launchDirection = launchMotion.Direction :: Vector3
	local launchVelocity = launchMotion.Velocity :: number

	-- Setup pie ammo
	local pieAmmoModel = getPieAmmoModel(pieModel, canCollide, noCollideTransparency)
	local pieAmmoMainPart = pieAmmoModel:FindFirstChild("MainPart") :: Part

	-- Tag the pie ammo model
	CollectionService:AddTag(pieAmmoModel, clientPieId)
	local uniquePieId = Instance.new("StringValue")
	uniquePieId.Name = "UniquePieId"
	uniquePieId.Value = clientPieId
	uniquePieId.Parent = pieAmmoModel

	-- Setup pie values
	local internalLaunchVelocity = launchDirection.Unit * launchVelocity
	pieAmmoModel:SetAttribute("InternalLaunchVelocity", internalLaunchVelocity)
	local pieCreator = Instance.new("ObjectValue")
	pieCreator.Name = "Creator"
	pieCreator.Value = creatorPlayer
	pieCreator.Parent = pieAmmoModel
	local internalSpinByVelocity = pieSpinInfo.ByVelocity
	pieAmmoModel:SetAttribute("InternalSpinByVelocity", internalSpinByVelocity)
	local onlyCollideLocal = not canCollide
	pieAmmoModel:SetAttribute("OnlyCollideLocal", onlyCollideLocal)

	-- Setup pie effects
	local pieTool = pieModel.Parent :: Tool
	local pieSkins = pieTool:FindFirstChild("PieSkins") :: Folder
	local effectsList = pieSkins:FindFirstChild("EffectsList") :: ModuleScript
	local newEffectsList = effectsList:Clone()
	local pieSkinFolder = pieAmmoModel:FindFirstChild("PieSkin") :: Folder
	newEffectsList.Parent = pieSkinFolder

	-- Setup pie align orientation
	local pieAlignSpin = (pieSpinInfo.AlignSpin == true)
	local pieAlignOrientation = pieAmmoMainPart:FindFirstChild("AlignOrientation") :: AlignOrientation
	pieAlignOrientation.CFrame = CFrame.new(Vector3.zero, launchDirection.Unit)
	pieAlignOrientation.Enabled = pieAlignSpin

	-- Setup pie ammo position
	pieAmmoModel.Parent = workspace
	pieAmmoMainPart:PivotTo(launchCFrame)
	pieAmmoMainPart.Anchored = false

	-- Launch pie
	task.defer(function()
		newAmmo(pieAmmoModel)
	end)

	-- Remove pie after a while
	Debris:AddItem(pieAmmoModel, 12)
end

---------- Stick functions ----------
local function getPieFromPieId(pieId: string): Model?
	-- There should only be one pie tagged with the pie id
	local taggedObjects = CollectionService:GetTagged(pieId)
	if #taggedObjects ~= 1 then
		return nil
	end

	-- Validate pie model
	local taggedPieModel = taggedObjects[1] :: Model
	local taggedPieMainPart = taggedPieModel and taggedPieModel:FindFirstChild("MainPart") :: Part
	local pieUniqueId = taggedPieModel and taggedPieModel:FindFirstChild("UniquePieId") :: StringValue
	if not (taggedPieModel and taggedPieModel:IsA("Model")) then
		return
	end 
	if not (taggedPieMainPart and taggedPieMainPart:IsA("Part")) then
		return
	end
	if not (pieUniqueId and pieId == pieUniqueId.Value) then
		return
	end

	return taggedPieModel
end

local function makeCSCPieVisible(pieModel: Model)
	-- Check for OnlyCollideLocal (is always true)
	local pieOnlyCollideLocal = pieModel:GetAttribute("OnlyCollideLocal") :: boolean
	if pieOnlyCollideLocal then
		return
	end

	-- Change pie's collision and touch
	for _, part in pieModel:GetDescendants() do
		if part:IsA("BasePart") then
			-- Transparency
			local originalTransparency = part:FindFirstChild("OriginalTransparency") :: NumberValue
			if originalTransparency then
				part.Transparency = originalTransparency.Value
			end

			-- Collision & touch
			local originalCanCollide = part:FindFirstChild("OriginalCanCollide") :: BoolValue
			if originalCanCollide then
				part.CanCollide = originalCanCollide.Value
			end
			local originalCanTouch = part:FindFirstChild("OriginalCanTouch") :: BoolValue
			if originalCanTouch then
				part.CanTouch = originalCanTouch.Value
			end
			local originalCanQuery = part:FindFirstChild("OriginalCanQuery") :: BoolValue
			if originalCanQuery then
				part.CanQuery = originalCanQuery.Value
			end
		end
	end
end

local function runClientHitEffect(throwPieMainPart: Part, hitPart: BasePart)
	-- Validate effect module
	local throwPieModel = throwPieMainPart.Parent :: Model
	local creatorObject = throwPieModel:FindFirstChild("Creator") :: ObjectValue
	local creatorPlayer = creatorObject and creatorObject.Value :: Player
	local throwPieSkinFolder = throwPieModel and throwPieModel:FindFirstChild("PieSkin")
	local throwPieSkinModel = throwPieSkinFolder and throwPieSkinFolder:FindFirstChildOfClass("Model")
	local pieEffectsConfiguration = throwPieSkinModel and throwPieSkinModel:FindFirstChild("EffectsConfiguration")
	local clientHitEffectModule = pieEffectsConfiguration and pieEffectsConfiguration:FindFirstChild("ClientHitEffect") :: ModuleScript
	if not clientHitEffectModule then
		return
	end

	-- Quick validation (redundant)
	local throwerCharacter = creatorPlayer.Character
	local throwerHumanoid = throwerCharacter and throwerCharacter:FindFirstChildOfClass("Humanoid")
	local creatorObjectValue = throwPieModel and throwPieModel:FindFirstChild("Creator") :: ObjectValue
	local creator = creatorObjectValue and creatorObjectValue.Value :: Player
	if throwerCharacter ~= creator.Character then
		return
	end

	-- Run effect
	local clientHitEffect = require(clientHitEffectModule) :: {[string]: any}
	clientHitEffect.onHit(throwerCharacter, throwPieMainPart, hitPart)
end

local function stickPiePartToPart(throwPieModel: Model, throwPieMainPart: Part, hitPart: BasePart, relativeCFrame: CFrame)
	-- Make pie visible
	task.defer(function()
		makeCSCPieVisible(throwPieModel)
	end)

	-- Disable forces and align orientation
	local upwardsForce = throwPieMainPart:FindFirstChild("UpwardsForce") :: VectorForce
	if upwardsForce then
		upwardsForce.Enabled = false
	end
	local alignOrientation = throwPieMainPart:FindFirstChild("AlignOrientation") :: AlignOrientation
	if alignOrientation then
		alignOrientation.Enabled = false
	end

	-- Offset main part and stick
	local targetCFrame = hitPart.CFrame:ToWorldSpace(relativeCFrame)
	throwPieMainPart:PivotTo(targetCFrame)
	local weldConstraint = Instance.new("WeldConstraint")
	weldConstraint.Part0 = throwPieMainPart
	weldConstraint.Part1 = hitPart
	weldConstraint.Parent = throwPieMainPart

	--print("CSC stick")

	-- Run hit effect (disabled for now)
	--runClientHitEffect(throwPieMainPart, hitPart)
end

local function onStickCSCPieToPart(throwPieId: string, hitPart: BasePart?, hitCFrame: CFrame, relativeCFrame: CFrame)
	-- Validate existence of parts
	task.desynchronize()
	local throwPieModel = getPieFromPieId(throwPieId)
	local throwPieMainPart = throwPieModel and throwPieModel:FindFirstChild("MainPart") :: Part
	if not (throwPieModel and throwPieMainPart and throwPieMainPart:IsA("Part") and throwPieMainPart:FindFirstChild("PieAttachment")) then
		return
	end
	if not (hitPart and hitPart:IsA("BasePart")) then
		return
	end

	-- Stick pie part
	task.synchronize()
	stickPiePartToPart(throwPieModel, throwPieMainPart, hitPart, relativeCFrame)
end

local function onStickCSCPieToCSCPie(throwPieId: string, hitPieId: string, hitCFrame: CFrame, relativeCFrame: CFrame)
	-- Validate existence of partrs
	local throwPieModel = getPieFromPieId(throwPieId)
	local throwPieMainPart = throwPieModel and throwPieModel:FindFirstChild("MainPart") :: Part
	local hitPieModel = getPieFromPieId(hitPieId)
	local hitPieMainPart = hitPieModel and hitPieModel:FindFirstChild("MainPart") :: Part
	if not (throwPieModel and throwPieMainPart and throwPieMainPart:FindFirstChild("PieAttachment") and throwPieMainPart:IsA("Part")) then
		return
	end
	if not (hitPieMainPart and hitPieMainPart:FindFirstChild("PieAttachment") and hitPieMainPart:IsA("Part")) then
		return
	end

	-- Stick pie part
	task.synchronize()
	stickPiePartToPart(throwPieModel, throwPieMainPart, hitPieMainPart, relativeCFrame)
end

---------- Event functions ----------

local function onCSCPieClientEvent(mode: string, ...)
	if mode == "Launch CSC Pie" then
		onLaunchCSCPie(...)
	elseif mode == "Stick CSC Pie To Part" then
		onStickCSCPieToPart(...)
	elseif mode == "Stick CSC Pie To CSC Pie" then
		onStickCSCPieToCSCPie(...)
	end
end

---------- Calling / connecting functions ----------

CSCPieRemoteEvent.OnClientEvent:Connect(onCSCPieClientEvent)
