--!strict

-- Client-Server-Client Pie Ammo Launcher
-- Creates & launches client pies fired by other players


---------- Validate container ----------

-- Replicated storage
if not script:FindFirstAncestorWhichIsA("ReplicatedStorage") then
	return
end


---------- Services ----------

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")


---------- Imports ----------

local CSCPieAmmo = require(script.Parent:WaitForChild("CSCPieAmmo"))

local _PieHiking_SharedStorage = ReplicatedStorage:WaitForChild("PieHiking_SharedStorage")
local _Modules = _PieHiking_SharedStorage:WaitForChild("Modules")
local BelovedRemote = require(_Modules:WaitForChild("BelovedRemote"))


---------- Types ----------

type FinalizedMotion = {["CFrame"]: CFrame?, ["Direction"]: Vector3?, ["Velocity"]: number?}
type SpinInfo = {["AlignSpin"]: boolean?, ["ByVelocity"]: boolean?}


---------- Local functions ----------

local newAmmo
local getCopiedPieAmmoModel
local onLaunchCSCPie

local getPieFromPieId
local makeCSCPieVisible
local stickPiePartToPart
local onStickCSCPieToCSCPie
local onStickCSCPieToPart


----- Launch functions -----

newAmmo = function(ammoModel: Model)
	if not ammoModel:IsA("Model") then
		return
	end
	local ammo = CSCPieAmmo.new(ammoModel)
	ammo:setUpAmmo()
	ammo:launchPie()
end

getCopiedPieAmmoModel = function(pieModel: Model, canCollide: boolean, noCollideTransparency: number): Model
	-- Clone the pie model
	local pieAmmoModel = pieModel:Clone()
	local pieAmmoMainPart = pieAmmoModel:FindFirstChild("MainPart")
	local pieAttachment = pieAmmoMainPart and pieAmmoMainPart:FindFirstChild("PieAttachment")
	local rigidConstraint = pieAmmoMainPart and pieAmmoMainPart:FindFirstChild("RigidConstraint")
	local upwardsForce = pieAmmoMainPart and pieAmmoMainPart:FindFirstChild("UpwardsForce")

	-- Set up objects
	for _, part in pieAmmoModel:GetDescendants() do
		if part:IsA("BasePart") then
			-- Transparency
			local originalTransparency = part:FindFirstChild("OriginalTransparency")
			local newTransparency
			if originalTransparency and originalTransparency:IsA("NumberValue") then
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
			local originalTransparency = part:FindFirstChild("OriginalTransparency")
			local newTransparency
			if originalTransparency and originalTransparency:IsA("NumberValue") then
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
	if rigidConstraint and rigidConstraint:IsA("RigidConstraint") then
		rigidConstraint.Enabled = false
		-- Notice: the constraint might connect to the original tool's Handle
	else
		warn(`[CSC Pie Ammo Launcher]: No rigid constraint found for pie model.`)
	end
	if upwardsForce and upwardsForce:IsA("VectorForce") then
		upwardsForce.Enabled = true
	else
		warn(`[CSC Pie Ammo Launcher]: No upwards force found for pie model.`)
	end

	return pieAmmoModel
end

onLaunchCSCPie = function(creatorPlayer: Player, launchMotion: FinalizedMotion, canCollide: boolean, noCollideTransparency: number, clientPieId: string, pieModel: Model, pieSpinInfo: SpinInfo)
	-- Validate pie info
	if not (pieModel and pieModel.Parent and typeof(clientPieId) == "string") then
		return
	end

	-- Get launch motion
	local launchCFrame = launchMotion.CFrame
	local launchDirection = launchMotion.Direction
	local launchVelocity = launchMotion.Velocity
	if not (launchCFrame and launchDirection and launchVelocity) then
		warn(`[CSC Pie Ammo Launcher]: Incomplete launch motion data.`)
		return
	end

	-- Setup pie ammo
	local pieAmmoModel = getCopiedPieAmmoModel(pieModel, canCollide, noCollideTransparency)
	local pieAmmoMainPart = pieAmmoModel:FindFirstChild("MainPart")
	if not (pieAmmoMainPart and pieAmmoMainPart:IsA("BasePart")) then
		warn(`[CSC Pie Ammo Launcher]: No main part found for pie model.`)
		return
	end

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
	local pieAlignOrientation = pieAmmoMainPart:FindFirstChild("AlignOrientation")
	if pieAlignOrientation and pieAlignOrientation:IsA("AlignOrientation") then
		pieAlignOrientation.CFrame = CFrame.new(Vector3.zero, launchDirection.Unit)
		pieAlignOrientation.Enabled = pieAlignSpin
	else
		warn(`[CSC Pie Ammo Launcher]: No align orientation found for pie model.`)
	end

	-- Setup pie ammo position
	pieAmmoMainPart:PivotTo(launchCFrame)
	pieAmmoMainPart.Anchored = false

	-- Launch pie
	newAmmo(pieAmmoModel)
end


----- Stick functions -----

getPieFromPieId = function(pieId: string): Model?
	-- There should only be one pie tagged with the pie id
	local taggedObjects = CollectionService:GetTagged(pieId)
	if #taggedObjects ~= 1 then
		return nil
	end

	-- Validate pie model
	local taggedPieModel = taggedObjects[1]
	local taggedPieMainPart = taggedPieModel and taggedPieModel:FindFirstChild("MainPart")
	local pieUniqueId = taggedPieModel and taggedPieModel:FindFirstChild("UniquePieId")
	if not (taggedPieModel and taggedPieModel:IsA("Model")) then
		return
	end 
	if not (taggedPieMainPart and taggedPieMainPart:IsA("BasePart")) then
		return
	end
	if not (pieUniqueId and pieUniqueId:IsA("StringValue")  and pieId == pieUniqueId.Value) then
		return
	end

	return taggedPieModel
end

makeCSCPieVisible = function(pieModel: Model)
	-- Check for OnlyCollideLocal (is always true)
	local pieOnlyCollideLocal = pieModel:GetAttribute("OnlyCollideLocal") == true
	if pieOnlyCollideLocal then
		return
	end

	-- Change pie's collision and touch
	for _, part in pieModel:GetDescendants() do
		if part:IsA("BasePart") then
			-- Transparency
			local originalTransparency = part:FindFirstChild("OriginalTransparency")
			if originalTransparency and originalTransparency:IsA("NumberValue") then
				part.Transparency = originalTransparency.Value
			end

			-- Collision & touch
			local originalCanCollide = part:FindFirstChild("OriginalCanCollide")
			if originalCanCollide and originalCanCollide:IsA("BoolValue") then
				part.CanCollide = originalCanCollide.Value
			end
			local originalCanTouch = part:FindFirstChild("OriginalCanTouch")
			if originalCanTouch and originalCanTouch:IsA("BoolValue") then
				part.CanTouch = originalCanTouch.Value
			end
			local originalCanQuery = part:FindFirstChild("OriginalCanQuery")
			if originalCanQuery and originalCanQuery:IsA("BoolValue") then
				part.CanQuery = originalCanQuery.Value
			end
		end
	end
end

stickPiePartToPart = function(throwPieModel: Model, throwPieMainPart: BasePart, hitPart: BasePart, relativeCFrame: CFrame)
	-- Make pie visible
	task.defer(function()
		makeCSCPieVisible(throwPieModel)
	end)

	-- Disable forces and align orientation
	local upwardsForce = throwPieMainPart:FindFirstChild("UpwardsForce")
	if upwardsForce and upwardsForce:IsA("VectorForce") then
		upwardsForce.Enabled = false
	else
		warn(`[CSC Pie Ammo Launcher]: No upwards force found for pie model.`)
	end
	local alignOrientation = throwPieMainPart:FindFirstChild("AlignOrientation")
	if alignOrientation and alignOrientation:IsA("AlignOrientation") then
		alignOrientation.Enabled = false
	else
		warn(`[CSC Pie Ammo Launcher]: No align orientation found for pie model.`)
	end

	-- Offset main part and stick
	local targetCFrame = hitPart.CFrame:ToWorldSpace(relativeCFrame)
	throwPieMainPart:PivotTo(targetCFrame)
	local weldConstraint = Instance.new("WeldConstraint")
	weldConstraint.Part0 = throwPieMainPart
	weldConstraint.Part1 = hitPart
	weldConstraint.Parent = throwPieMainPart
end

onStickCSCPieToPart = function(throwPieId: string, hitPart: BasePart?, hitCFrame: CFrame, relativeCFrame: CFrame)
	-- Validate existence of parts
	local throwPieModel = getPieFromPieId(throwPieId)
	local throwPieMainPart = throwPieModel and throwPieModel:FindFirstChild("MainPart")
	if not (throwPieModel and throwPieMainPart and throwPieMainPart:IsA("BasePart") and throwPieMainPart:FindFirstChild("PieAttachment")) then
		return
	end
	if not (hitPart and hitPart:IsA("BasePart")) then
		return
	end

	-- Stick pie part
	stickPiePartToPart(throwPieModel, throwPieMainPart, hitPart, relativeCFrame)
end

onStickCSCPieToCSCPie = function(throwPieId: string, hitPieId: string, hitCFrame: CFrame, relativeCFrame: CFrame)
	-- Validate existence of parts
	local throwPieModel = getPieFromPieId(throwPieId)
	local throwPieMainPart = throwPieModel and throwPieModel:FindFirstChild("MainPart")
	local hitPieModel = getPieFromPieId(hitPieId)
	local hitPieMainPart = hitPieModel and hitPieModel:FindFirstChild("MainPart")
	if not (throwPieModel and throwPieMainPart and throwPieMainPart:FindFirstChild("PieAttachment") and throwPieMainPart:IsA("BasePart")) then
		return
	end
	if not (hitPieMainPart and hitPieMainPart:FindFirstChild("PieAttachment") and hitPieMainPart:IsA("BasePart")) then
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
