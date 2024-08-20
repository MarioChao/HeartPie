--!strict
-- Pie Ammo Module

---------- Module ----------
local PieAmmo = {}
PieAmmo.__index = PieAmmo

---------- Services ----------

local Debris = game:GetService("Debris")
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

---------- Instances ----------

local PieHikingEvents = ReplicatedStorage:WaitForChild("PieHikingEvents") :: Folder
local PieHikeRemoteEvent = PieHikingEvents:WaitForChild("PieHikeRemoteEvent") :: RemoteEvent
local CSCPieRemoteEvent = PieHikingEvents:WaitForChild("CSCPieRemoteEvent") :: RemoteEvent

---------- Variables ----------

local unstickPieTime = 7.5
local removePieTime = 12

---------- Local functions ----------

local function getConnectedCharacter(instance: Instance?): Model?
	-- Find a player's character by looking through root parts and parent instances
	local loopCount = 0
	local rootTable = {instance}
	while instance and loopCount < 20 do
		-- Check if instance is a character with a humanoid
		if instance:IsA("Model") and instance:FindFirstChildOfClass("Humanoid") then
			return instance
		end

		-- Update variables
		local parent: Instance? = instance.Parent
		if instance:IsA("BasePart") then
			-- Check the root part only if not checked yet
			if not table.find(rootTable, instance.AssemblyRootPart) then
				parent = instance.AssemblyRootPart
				table.insert(rootTable, instance.AssemblyRootPart)
			end
		end
		instance = parent
		loopCount += 1
	end
	return nil
end

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

local function getPieModel(instance: Instance?): Model?
	-- Find a pie model by looking through the parent instances
	local loopCount = 0
	while instance and loopCount < 20 do
		-- Check if instance is a pie model
		if instance:IsA("Model") and instance.Name == "PieModel" and instance:FindFirstChild("MainPart") then
			return instance
		end

		-- Update variables
		local parent: Instance? = instance:FindFirstAncestorWhichIsA("Model")
		instance = parent
		loopCount += 1
	end
	return nil
end

---------- Module functions ----------

-- Constructor
function PieAmmo.new(ammoModel: Model, hasHitCharacterEffect: boolean)
	local self = setmetatable({}, PieAmmo)

	-- Ammo Info
	self.AmmoModel = ammoModel
	self.AmmoMainPart = self.AmmoModel:WaitForChild("MainPart") :: Part
	self.AmmoSounds = {
		["Fire"] = self.AmmoMainPart:WaitForChild("FireSound") :: Sound,
		["Hit"] = self.AmmoMainPart:WaitForChild("HitSound") :: Sound
	}
	self.AmmoInternalLaunchVelocity = self.AmmoModel:GetAttribute("InternalLaunchVelocity") :: Vector3
	self.AmmoCreator = self.AmmoModel:WaitForChild("Creator") :: ObjectValue
	self.AmmoPieSpins = self.AmmoModel:GetAttribute("InternalSpinByVelocity") :: boolean
	self.AmmoCanOverlapPart = self.AmmoModel:GetAttribute("CanOverlapPart") :: boolean

	-- Variables
	self.pieStuck = false
	self.launchTime = nil :: number?
	self.HasHitCharacterEffect = hasHitCharacterEffect
	self.Connections = {} :: {RBXScriptConnection}

	-- Check valid
	local isValid = true
	if not (self.AmmoInternalLaunchVelocity and self.AmmoMainPart:FindFirstChild("PieAttachment")) then
		isValid = false
	end
	local character = self.AmmoCreator and self.AmmoCreator.Value.Character
	local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart") :: Part
	local throwDistance = humanoidRootPart and (self.AmmoMainPart.Position - humanoidRootPart.Position).Magnitude
	local maxThrowDistance = humanoidRootPart and (20 + humanoidRootPart.AssemblyLinearVelocity.Magnitude / 6)
	if not humanoidRootPart or (throwDistance > maxThrowDistance) then
		isValid = false
	end

	-- Return
	if not isValid then
		self.AmmoModel = nil
		self.AmmoMainPart = nil
		self.AmmoSounds = nil
		self.AmmoInternalLaunchVelocity = nil
		self.AmmoCreator = nil
		self.AmmoPieSpins = nil
		self.AmmoCanOverlapPart = nil
	end
	return self
end

-- Functions

function PieAmmo:canStickTo(hitPart: BasePart): boolean
	-- Check if the current pie is a Client pie
	local uniquePieId = self.AmmoModel:FindFirstChild("UniquePieId") :: StringValue
	local pieTag = uniquePieId and uniquePieId.Value
	local isThrowClientPie = pieTag

	-- Check if hit part is a Client or CSC pie
	local hitPieModel = getPieModel(hitPart)
	local hitPieMainPart = hitPieModel and hitPieModel:FindFirstChild("MainPart") :: Part
	local hitPieUniqueId = hitPieModel and hitPieModel:FindFirstChild("UniquePieId") :: StringValue
	local hitPieTag = hitPieUniqueId and hitPieUniqueId.Value
	local isHitClientPie = hitPieMainPart and hitPieMainPart:IsA("Part") and hitPieTag and typeof(hitPieTag) == "string"

	-- Return
	if (isThrowClientPie) or (not isThrowClientPie and not isHitClientPie) then
		return true
	end
	return false
end

function PieAmmo:runClientHitEffect(hitPart: BasePart)
	-- Validate effect module
	local creatorPlayer = self.AmmoCreator.Value :: Player
	local throwPieModel = self.AmmoModel
	local throwPieMainPart = self.AmmoMainPart
	local throwPieSkinFolder = throwPieModel:FindFirstChild("PieSkin")
	local throwPieSkinModel = throwPieSkinFolder and throwPieSkinFolder:FindFirstChildOfClass("Model")
	local pieEffectsConfiguration = throwPieSkinModel and throwPieSkinModel:FindFirstChild("EffectsConfiguration")
	local clientHitEffectModule = pieEffectsConfiguration and pieEffectsConfiguration:FindFirstChild("ClientHitEffect") :: ModuleScript
	if not clientHitEffectModule then
		return
	end

	-- Quick validation
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

function PieAmmo:stickPieReplicate(hitPart: BasePart, relativeCFrame: CFrame)
	-- Check if hit part is a Client or CSC pie
	task.desynchronize()
	local hitPieModel = getPieModel(hitPart)
	local hitPieMainPart = hitPieModel and hitPieModel:FindFirstChild("MainPart") :: Part
	local hitPieUniqueId = hitPieModel and hitPieModel:FindFirstChild("UniquePieId") :: StringValue
	local hitPieTag = hitPieUniqueId and hitPieUniqueId.Value
	local isHitClientPie = hitPieMainPart and hitPieMainPart:IsA("Part") and hitPieTag and typeof(hitPieTag) == "string"

	-- Check if the current pie is a Client pie
	local uniquePieId = self.AmmoModel:FindFirstChild("UniquePieId") :: StringValue
	local pieTag = uniquePieId and uniquePieId.Value
	if not pieTag then
		--[[ Current pie is a Server pie ]]

		-- Check if hit part is a Client or CSC pie
		task.synchronize()
		if isHitClientPie and hitPieMainPart then
			-- [[ Hit a Client pie or CSC pie]]
			relativeCFrame = hitPieMainPart.CFrame:ToObjectSpace(self.AmmoMainPart.CFrame)
			PieHikeRemoteEvent:FireServer("Stick Server Pie To CSC Pie", self.AmmoMainPart, hitPieTag, hitPieMainPart.CFrame, hitPieMainPart.Size, relativeCFrame)
		else
			--[[ Hit a non-Client-pie or non-CSC-pie part ]]
			PieHikeRemoteEvent:FireServer("Stick Server Pie To Part", self.AmmoMainPart, hitPart, hitPart.CFrame, relativeCFrame)
		end
	else
		--[[ Current pie is a Client pie ]]

		-- Check if hit part is a Client or CSC pie
		task.synchronize()
		if not (hitPieMainPart and isHitClientPie) then
			--[[ Hit a non-Client-pie or non-CSC-pie part ]]
			CSCPieRemoteEvent:FireServer("Stick CSC Pie To Part", pieTag, hitPart, hitPart.CFrame, relativeCFrame)
		else
			--[[ Hit a Client pie or CSC pie ]]
			relativeCFrame = hitPieMainPart.CFrame:ToObjectSpace(self.AmmoMainPart.CFrame)
			CSCPieRemoteEvent:FireServer("Stick CSC Pie To CSC Pie", pieTag, hitPieTag, hitPieMainPart.CFrame, relativeCFrame)
		end

		-- Run hit effect
		self:runClientHitEffect(hitPart)
	end
end

function PieAmmo:stickPie(hitPart: BasePart, relativeCFrame: CFrame)
	-- Validate ammo main part
	task.desynchronize()
	local mainPart = self.AmmoMainPart :: Part
	if not mainPart then
		return
	end

	-- Stick pie in the other environments
	task.defer(function()
		self:stickPieReplicate(hitPart, relativeCFrame)
	end)

	-- Disable forces and align orientation in the client
	task.synchronize()
	local upwardsForce = mainPart:FindFirstChild("UpwardsForce") :: VectorForce
	if upwardsForce then
		upwardsForce.Enabled = false
	end
	local alignOrientation = mainPart:FindFirstChild("AlignOrientation") :: AlignOrientation
	if alignOrientation then
		alignOrientation.Enabled = false
	end

	-- Stick pie in the client
	local targetCFrame = hitPart.CFrame:ToWorldSpace(relativeCFrame)
	mainPart:PivotTo(targetCFrame)
	mainPart.CanCollide = false
	local weldConstraint = Instance.new("WeldConstraint")
	weldConstraint.Part0 = mainPart
	weldConstraint.Part1 = hitPart
	weldConstraint.Parent = mainPart
	mainPart.CanCollide = true
end

function PieAmmo:unstickPie()
	-- Validate ammo main part
	if not self.AmmoMainPart then
		return
	end

	-- Unstick pie in the server
	PieHikeRemoteEvent:FireServer("Unstick", self.AmmoMainPart)

	-- Unstick pie in the script
	for _, instance in self.AmmoMainPart:GetChildren() do
		if instance:IsA("WeldConstraint") and instance.Enabled then
			instance.Enabled = false
		end
	end
end

function PieAmmo:removePie()
	-- Validate ammo model
	if not self.AmmoModel then
		return
	end

	-- Remove pie in the server
	PieHikeRemoteEvent:FireServer("Remove", self.AmmoModel)

	-- Remove pie in the script
	Debris:AddItem(self.AmmoModel, 0)
end

function PieAmmo:launchPie()
	-- Validate ammo main part
	if not self.AmmoMainPart then
		print("not main part")
		return
	end

	-- Configure and shoot pie with initial velocity
	self.launchTime = os.clock()
	self.AmmoSounds.Fire:Play()
	-- Check if ammo is not stuck before giving velocity
	local ammoMainPart = self.AmmoMainPart :: Part
	local ammoAssemblyRootPart = ammoMainPart.AssemblyRootPart
	if ammoAssemblyRootPart and ammoAssemblyRootPart:IsDescendantOf(self.AmmoModel) then
		self.AmmoMainPart.AssemblyLinearVelocity = self.AmmoInternalLaunchVelocity
	end
	if self.AmmoPieSpins then
		self:matchAmmoSpin()
	end

	-- Unstick seconds after launch
	task.wait(unstickPieTime + self.launchTime - os.clock())
	self:unstickPie()

	-- Remove seconds after launch
	task.wait(removePieTime + self.launchTime - os.clock())
	self:cleanup()
end

function PieAmmo:matchAmmoSpin()
	-- Validate align orientation
	local mainPart = self.AmmoMainPart :: Part
	local alignOrientation = mainPart and mainPart:FindFirstChild("AlignOrientation") :: AlignOrientation
	if not (mainPart and alignOrientation and alignOrientation.Enabled) then
		return
	end

	-- Match align orientation's CFrame with main part's velocity
	local connection = RunService.Heartbeat:Connect(function()
		if mainPart and alignOrientation then
			alignOrientation.CFrame = CFrame.new(Vector3.zero, mainPart.AssemblyLinearVelocity.Unit)
		end
	end)
	table.insert(self.Connections, connection)
end

function PieAmmo:onTouched(otherPart: BasePart, mainPartRelativeCFrame: CFrame)
	-- Validate touch
	task.desynchronize()
	if not (otherPart and otherPart.Parent) then
		return
	end

	-- Validate not stuck
	if self.pieStuck then
		return
	end

	-- Validate unstick time
	if not (os.clock() - self.launchTime <= unstickPieTime) then
		return
	end

	-- Check for touching non-pvp character
	local touchedCharacter = getConnectedCharacter(otherPart)
	local creatorPlayer = self.AmmoCreator.Value :: Player
	if creatorPlayer and touchedCharacter and (creatorPlayer.Character == touchedCharacter or not checkCanHitCharacter(creatorPlayer.Character, touchedCharacter)) then
		return
	end

	-- Validate hitting pie
	if not self:canStickTo(otherPart) then
		return
	end

	-- Stick pie
	task.synchronize()
	if self.pieStuck then
		return
	end
	self.pieStuck = true
	self.AmmoSounds.Hit:Play()
	task.defer(function()
		self:stickPie(otherPart, mainPartRelativeCFrame)

		-- Hit character effect
		if creatorPlayer and touchedCharacter and self.HasHitCharacterEffect then
			PieHikeRemoteEvent:FireServer("Pie Hit Character Effect", creatorPlayer.Character, touchedCharacter, self.AmmoMainPart)
		end
	end)
end

function PieAmmo:_onTouched(otherPart: BasePart)
	-- Validate not self
	if otherPart.AssemblyRootPart == self.AmmoMainPart.AssemblyRootPart then
		return
	end

	-- Validate can touch
	task.synchronize()
	if not otherPart.CanTouch then
		return
	end
	if not PhysicsService:CollisionGroupsAreCollidable(self.AmmoMainPart.CollisionGroup, otherPart.CollisionGroup) then
		return
	end

	-- Calculate immediate offset
	local mainPartRelativeCFrame = otherPart.CFrame:ToObjectSpace(self.AmmoMainPart.CFrame)

	self:onTouched(otherPart, mainPartRelativeCFrame)
end

function PieAmmo:setupAmmo()
	-- Validate ammo model
	if not self.AmmoModel then
		return
	end
	self.launchTime = os.clock()
	-- Connect Touched events on every physical pie parts
	for _, part in self.AmmoModel:GetDescendants() do
		if part:IsA("BasePart") and part.CanTouch then
			-- Touched connection
			local connection = part.Touched:Connect(function(otherPart: BasePart)
				self:_onTouched(otherPart)
			end)
			table.insert(self.Connections, connection)

			-- Check initial touched
			if self.AmmoCanOverlapPart then
				task.defer(function()
					local touchingParts = workspace:GetPartsInPart(part)
					for _, otherPart in touchingParts do
						self:_onTouched(otherPart)
					end
				end)
			end
		end
	end
end

function PieAmmo:cleanup()
	self:removePie()
	for _, connection in self.Connections do
		if connection.Connected then
			connection:Disconnect()
			connection = nil
		end
	end
end

function PieAmmo:destroy()
	self:cleanup()
end

return PieAmmo
