--!strict

-- Client-Server-Client Pie Ammo Launcher
-- Creates & launches client pies fired by other players


---------- Services ----------

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")


---------- Imports ----------

local CSCPieAmmo = require(script.Parent:WaitForChild("CSCPieAmmo"))

local _PieHikingSharedStorage = ReplicatedStorage:WaitForChild("PieHikingSharedStorage")
local _EffectModules = _PieHikingSharedStorage:WaitForChild("EffectModules")
local PieHitEffects = require(_EffectModules:WaitForChild("PieHitEffects"))

local _Modules = _PieHikingSharedStorage:WaitForChild("Modules")
local BelovedRemote = require(_Modules:WaitForChild("BelovedRemote"))


---------- Types ----------

type FinalizedMotion = {["CFrame"]: CFrame?, ["Direction"]: Vector3?, ["Velocity"]: number?}
type SpinInfo = {["AlignSpin"]: boolean?, ["ByVelocity"]: boolean?}


---------- Local functions ----------

local newAmmo
local getPieAmmoModel
local onLaunchCSCPie

local getPieFromPieId
local makeCSCPieVisible
local runClientHitEffect
local stickPiePartToPart
local onStickCSCPieToCSCPie
local onStickCSCPieToPart


----- Launch functions -----

newAmmo = function(ammoModel: Model)
	if not ammoModel:IsA("Model") then
		return
	end
	local ammo = CSCPieAmmo.new(ammoModel, false)
	ammo:launchPie()
end

getPieAmmoModel = function(pieModel: Model, canCollide: boolean, noCollideTransparency: number): Model
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

onLaunchCSCPie = function(creatorPlayer: Player, launchMotion: FinalizedMotion, canCollide: boolean, noCollideTransparency: number, clientPieId: string, pieModel: Model, pieSpinInfo: SpinInfo)
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
	local launchVelocity_Vector3 = launchDirection.Unit * launchVelocity
	pieAmmoModel:SetAttribute("_LaunchVelocity", launchVelocity_Vector3)
	local pieCreator = Instance.new("ObjectValue")
	pieCreator.Name = "Creator"
	pieCreator.Value = creatorPlayer
	pieCreator.Parent = pieAmmoModel
	local willSpinByVelocity = pieSpinInfo.ByVelocity
	pieAmmoModel:SetAttribute("_SpinByVelocity", willSpinByVelocity)
	local onlyCollideLocal = not canCollide
	pieAmmoModel:SetAttribute("OnlyCollideLocal", onlyCollideLocal)

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
end


----- Stick functions -----

getPieFromPieId = function(pieId: string): Model?
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

makeCSCPieVisible = function(pieModel: Model)
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

runClientHitEffect = function(throwPieMainPart: Part, hitPart: BasePart)
	-- Quick validation
	local throwPieModel = throwPieMainPart.Parent :: Model
	local creatorObject = throwPieModel:FindFirstChild("Creator") :: ObjectValue
	local creator = creatorObject and creatorObject.Value :: Player
	local throwerCharacter = creator and creator.Character
	local throwerHumanoid = throwerCharacter and throwerCharacter:FindFirstChildOfClass("Humanoid")
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
	local throwPieSkinFolder = throwPieModel:FindFirstChild("PieSkin")
	local throwPieSkinModel = throwPieSkinFolder and throwPieSkinFolder:FindFirstChildOfClass("Model")
	if not throwPieSkinModel then
		return
	end
	local effectInfo = PieHitEffects[throwPieSkinModel.Name]
	if not effectInfo then
		return
	end
	local effectFunction = (effectInfo.ClientUseServer and effectInfo.ServerHit) or effectInfo.ClientHit
	if not effectFunction then
		return
	end

	-- Run effect
	effectFunction(param)
end

stickPiePartToPart = function(throwPieModel: Model, throwPieMainPart: Part, hitPart: BasePart, relativeCFrame: CFrame)
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

onStickCSCPieToPart = function(throwPieId: string, hitPart: BasePart?, hitCFrame: CFrame, relativeCFrame: CFrame)
	-- Validate existence of parts
	local throwPieModel = getPieFromPieId(throwPieId)
	local throwPieMainPart = throwPieModel and throwPieModel:FindFirstChild("MainPart") :: Part
	if not (throwPieModel and throwPieMainPart and throwPieMainPart:IsA("Part") and throwPieMainPart:FindFirstChild("PieAttachment")) then
		return
	end
	if not (hitPart and hitPart:IsA("BasePart")) then
		return
	end

	-- Stick pie part
	stickPiePartToPart(throwPieModel, throwPieMainPart, hitPart, relativeCFrame)
end

onStickCSCPieToCSCPie = function(throwPieId: string, hitPieId: string, hitCFrame: CFrame, relativeCFrame: CFrame)
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
	stickPiePartToPart(throwPieModel, throwPieMainPart, hitPieMainPart, relativeCFrame)
end


----- Main -----

local function main()
	if RunService:IsClient() then
		-- Connect events
		BelovedRemote.connect_toClient("Launch CSC Pie", onLaunchCSCPie)
		BelovedRemote.connect_toClient("Stick CSC Pie To Part", onStickCSCPieToPart)
		BelovedRemote.connect_toClient("Stick CSC Pie To CSC Pie", onStickCSCPieToCSCPie)

		-- Belove
		BelovedRemote.belovePlayer_RE_toServer("Launch CSC Pie")
		BelovedRemote.belovePlayer_RE_toServer("Stick CSC Pie To Part")
		BelovedRemote.belovePlayer_RE_toServer("Stick CSC Pie To CSC Pie")
	end
end


---------- Calling function ----------

main()
