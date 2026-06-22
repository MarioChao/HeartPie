--!strict

-- Regular Pie Ammo Class


---------- Services ----------

local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")


---------- Imports ----------

local _PieHiking_SharedStorage = ReplicatedStorage:WaitForChild("PieHiking_SharedStorage")
local _EffectModules = _PieHiking_SharedStorage:WaitForChild("EffectModules")
local PieHitEffectsGetter = require(_EffectModules:WaitForChild("PieHitEffectsGetter"))

local _AmmoModules = _PieHiking_SharedStorage:WaitForChild("AmmoModules")
local AmmoUtil = require(_AmmoModules:WaitForChild("AmmoUtil"))

local _Modules = _PieHiking_SharedStorage:WaitForChild("Modules")
local BelovedRemote = require(_Modules:WaitForChild("BelovedRemote"))

local _SoundModules = _PieHiking_SharedStorage:WaitForChild("SoundModules")
local SoundEffectsGetter = require(_SoundModules:WaitForChild("SoundEffectsGetter"))

local ServerPieAmmoApi
if RunService:IsServer() then
	local ServerScriptService = game:GetService("ServerScriptService")
	local _PieHiking_ServerScripts = ServerScriptService:WaitForChild("PieHiking_ServerScripts")
	local _ServerAmmoModules = _PieHiking_ServerScripts:WaitForChild("ServerAmmoModules")
	ServerPieAmmoApi = require(_ServerAmmoModules:WaitForChild("ServerPieAmmoApi"))
end


---------- Constants ----------

local Constants = {}

Constants.timeFunction = time

table.freeze(Constants)


---------- Class ----------

local PieAmmo = {}
PieAmmo.__index = PieAmmo


----- Class types -----

type CFieldData = {
	isValid: boolean,

	ammoModel: Model,
	ammoMainPart: BasePart?,
	ammoInternalLaunchVelocity: Vector3,
	ammoCreator: ObjectValue,
	ammoPieSpins: boolean,
	ammoCanOverlapPart: boolean,

	ammoPieConfig: Configuration,
	extraUnstickPieDelayConfig: Configuration,
	extraRemovePieDelayConfig: Configuration,
	ammoPieStates: Configuration,

	isPieStuck: boolean,
	launchStartTime: number,
	hasHitCharacterEffect: boolean,
	disabledCharacterCollisions: {[Model]: {NoCollisionConstraint}},
	connections: {RBXScriptConnection},
}

export type CObjectType = typeof(setmetatable({} :: CFieldData, PieAmmo))


----- Class fields -----

--- Constructor ---

function PieAmmo.new(ammoModel: Model, hasHitCharacterEffect: boolean)
	local self = setmetatable({}, PieAmmo) :: CObjectType

	-- Ammo Info
	self.ammoModel = ammoModel
	self.ammoMainPart = self.ammoModel:WaitForChild("MainPart") :: BasePart
	self.ammoInternalLaunchVelocity = self.ammoModel:GetAttribute("_LaunchVelocity") :: Vector3
	self.ammoCreator = self.ammoModel:WaitForChild("Creator") :: ObjectValue
	self.ammoPieSpins = self.ammoModel:GetAttribute("_SpinByVelocity") :: boolean
	self.ammoCanOverlapPart = self.ammoModel:GetAttribute("_CanOverlapPart") :: boolean

	-- Values
	local pieValues = self.ammoModel:WaitForChild("PieValues") :: Folder
	self.ammoPieConfig = pieValues:WaitForChild("PieConfig") :: Configuration
	self.extraUnstickPieDelayConfig = self.ammoPieConfig:WaitForChild("ExtraUnstickPieDelay") :: Configuration
	self.extraRemovePieDelayConfig = self.ammoPieConfig:WaitForChild("ExtraRemovePieDelay") :: Configuration
	self.ammoPieStates = pieValues:WaitForChild("PieStates") :: Configuration

	-- Variables
	self.isPieStuck = false
	self.launchStartTime = 0
	self.hasHitCharacterEffect = hasHitCharacterEffect
	self.disabledCharacterCollisions = {}
	self.connections = {}

	-- Check valid
	self.isValid = true
	if not self.ammoInternalLaunchVelocity then
		self.isValid = false
	end
	if not (self.ammoMainPart and self.ammoMainPart:FindFirstChild("PieAttachment")) then
		self.isValid = false
	end
	if self.ammoMainPart then
		local creator = self.ammoCreator and self.ammoCreator.Value
		if creator and creator:IsA("Player") then
			local character = creator.Character
			local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart") :: Part
			local throwDistance = humanoidRootPart and (self.ammoMainPart.Position - humanoidRootPart.Position).Magnitude
			local maxThrowDistance = humanoidRootPart and (20 + humanoidRootPart.AssemblyLinearVelocity.Magnitude / 6)
			if not humanoidRootPart or (throwDistance > maxThrowDistance) then
				self.isValid = false
			end
		end
	end

	-- Return
	return self
end


--- Pie functions ---

function PieAmmo.setUpAmmo(self: CObjectType)
	-- Validate ammo
	if not (self.ammoMainPart and self.isValid) then
		warn(`[Regular Pie Ammo]: Invalid ammo.`)
		return
	end

	-- Connect Touched events on every physical pie parts
	for _, part in self.ammoModel:GetDescendants() do
		if part:IsA("BasePart") and part.CanTouch then
			-- Touched connection
			local connection = part.Touched:Connect(function(otherPart: BasePart)
				self:_onTouched(otherPart)
			end)
			table.insert(self.connections, connection)

			-- Check initial touched
			if self.ammoCanOverlapPart then
				task.defer(function()
					local touchingParts = workspace:GetPartsInPart(part)
					for _, otherPart in touchingParts do
						self:_onTouched(otherPart)
					end
				end)
			end
		end
	end

	-- Set massless
	self.ammoMainPart.Massless = false
end

function PieAmmo.launchPie(self: CObjectType)
	-- Validate ammo main part
	if not self.ammoMainPart then
		warn(`[Regular Pie Ammo]: No main part.`)
		return
	end

	-- Parent to workspace
	self.ammoModel.Parent = workspace

	-- Set network owner
	if RunService:IsServer() then
		self.ammoMainPart:SetNetworkOwner(nil)
	end

	-- Configure and shoot pie with initial velocity
	self.launchStartTime = Constants.timeFunction()
	self.ammoPieStates:SetAttribute("LaunchStartTime", self.launchStartTime)
	self:playSoundEffect("fire")

	-- Check if ammo is not stuck before giving velocity
	local ammoMainPart = self.ammoMainPart
	local ammoAssemblyRootPart = ammoMainPart.AssemblyRootPart
	if ammoAssemblyRootPart and ammoAssemblyRootPart:IsDescendantOf(self.ammoModel) then
		self.ammoMainPart.AssemblyLinearVelocity = self.ammoInternalLaunchVelocity
	end

	-- Align pie spin
	if self.ammoPieSpins then
		self:matchAmmoSpin()
	end

	-- Unstick seconds after launch
	while true do
		if Constants.timeFunction() >= self.launchStartTime + self:getUnstickPieDelay() then
			break
		end
		task.wait()
	end
	self:unstickPie()

	-- Remove seconds after launch
	while true do
		if Constants.timeFunction() >= self.launchStartTime + self:getRemovePieDelay() then
			break
		end
		task.wait()
	end
	self:cleanup()
end

function PieAmmo.canStickTo(self: CObjectType, hitPart: BasePart): boolean
	-- Check if the current pie is a Client pie
	local uniquePieId = self.ammoModel:FindFirstChild("UniquePieId")
	local pieTag = (uniquePieId and uniquePieId:IsA("StringValue") and uniquePieId.Value) or nil
	local isThrowClientPie = pieTag ~= nil

	-- Check if hit part is a Client or CSC pie
	local hitPieModel = AmmoUtil.getPieModel(hitPart)
	local isHitClientPie = hitPieModel and AmmoUtil.isPieAClientPie(hitPieModel)

	-- Return
	if isThrowClientPie or not isHitClientPie then
		return true
	end
	return false
end

function PieAmmo.runClientHitEffect(self: CObjectType, hitPart: BasePart)
	if not self.ammoMainPart then
		return
	end

	-- Get character
	local creatorPlayer = self.ammoCreator.Value
	if not (creatorPlayer and creatorPlayer:IsA("Player")) then
		warn(`[Regular Pie Ammo]: Invalid creator player.`)
		return
	end
	local throwerCharacter = creatorPlayer.Character
	if not (throwerCharacter and throwerCharacter:IsA("Model")) then
		warn(`[Regular Pie Ammo]: Invalid character.`)
		return
	end

	-- Get parameters
	local ammoModel = self.ammoModel
	local ammoMainPart = self.ammoMainPart
	local param: PieHitEffectsGetter.EffectParameter = {
		throwerCharacter = throwerCharacter,
		hitCharacter = nil,
		pieMainPart = ammoMainPart,
		hitPart = hitPart,
	}

	-- Get effect function
	local throwPieSkinFolder = ammoModel:FindFirstChild("PieSkin")
	local throwPieSkinModel = throwPieSkinFolder and throwPieSkinFolder:FindFirstChildOfClass("Model")
	if not throwPieSkinModel then
		return
	end
	local effectInfo = PieHitEffectsGetter.getValueAt(throwPieSkinModel.Name)
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

function PieAmmo.stickPieReplicate(self: CObjectType, hitPart: BasePart, relativeCFrame: CFrame)
	if not self.ammoMainPart then
		return
	end

	-- Check if hit part is a Client or CSC pie
	local hitPieModel = AmmoUtil.getPieModel(hitPart)
	local hitPieMainPart = hitPieModel and hitPieModel:FindFirstChild("MainPart")
	local hitPieUniqueId = hitPieModel and hitPieModel:FindFirstChild("UniquePieId")
	local hitPieTag = (hitPieUniqueId and hitPieUniqueId:IsA("StringValue") and hitPieUniqueId.Value) or nil
	local isHitClientPie = hitPieModel and AmmoUtil.isPieAClientPie(hitPieModel)

	-- Check if the current pie is a Client pie
	local isClientPie = AmmoUtil.isPieAClientPie(self.ammoModel)

	-- Stick pie
	if not isClientPie then
		--[[ Current pie is a Server pie ]]

		-- Server pies can't hit client parts

		--[[ Hit a server part ]]
		if ServerPieAmmoApi then
			ServerPieAmmoApi.stickServerPieToPart(self.ammoMainPart, hitPart, hitPart.CFrame, relativeCFrame)
		end
	else
		--[[ Current pie is a Client pie ]]

		-- Get pie tag
		local uniquePieId = self.ammoModel:FindFirstChild("UniquePieId")
		if not (uniquePieId and uniquePieId:IsA("StringValue")) then
			warn(`[Regular Pie Ammo]: No UniquePieId found for pie model.`)
			return
		end
		local pieTag = uniquePieId.Value

		-- Check if hit part is a Client or CSC pie
		if isHitClientPie and hitPieMainPart and hitPieMainPart:IsA("BasePart") then
			--[[ Hit a Client pie or CSC pie ]]
			relativeCFrame = hitPieMainPart.CFrame:ToObjectSpace(self.ammoMainPart.CFrame)
			BelovedRemote.fire_toServer("Stick CSC Pie To CSC Pie", pieTag, hitPieTag, hitPieMainPart.CFrame, relativeCFrame)
		else
			--[[ Hit a non-Client-pie or non-CSC-pie part ]]
			BelovedRemote.fire_toServer("Stick CSC Pie To Part", pieTag, hitPart, hitPart.CFrame, relativeCFrame)
		end

		-- Run hit effect
		self:runClientHitEffect(hitPart)
	end
end

function PieAmmo.stickPie(self: CObjectType, hitPart: BasePart, relativeCFrame: CFrame)
	-- Validate ammo main part
	local mainPart = self.ammoMainPart
	if not mainPart then
		return
	end

	-- Stick pie in the other environments
	task.defer(function()
		self:stickPieReplicate(hitPart, relativeCFrame)
	end)

	-- Disable forces and align orientation in current environment
	local upwardsForce = mainPart:FindFirstChild("UpwardsForce")
	if upwardsForce and upwardsForce:IsA("VectorForce") then
		upwardsForce.Enabled = false
	else
		warn(`[Regular Pie Ammo]: No upwards force found for pie model.`)
	end
	local alignOrientation = mainPart:FindFirstChild("AlignOrientation")
	if alignOrientation and alignOrientation:IsA("AlignOrientation") then
		alignOrientation.Enabled = false
	else
		warn(`[Regular Pie Ammo]: No align orientation found for pie model.`)
	end

	-- Stick pie in current environment
	local targetCFrame = hitPart.CFrame:ToWorldSpace(relativeCFrame)
	AmmoUtil.setPieCollision(self.ammoModel, false)
	mainPart:PivotTo(targetCFrame)
	local weldConstraint = Instance.new("WeldConstraint")
	weldConstraint.Part0 = mainPart
	weldConstraint.Part1 = hitPart
	AmmoUtil.setPieCollision(self.ammoModel)
	weldConstraint.Parent = mainPart
end

function PieAmmo.unstickPie(self: CObjectType)
	-- Validate ammo main part
	if not self.ammoMainPart then
		return
	end

	-- Unstick pie in the server
	if ServerPieAmmoApi then
		ServerPieAmmoApi.unstickServerPie(self.ammoMainPart)
	end

	-- Unstick pie in the script
	for _, instance in self.ammoMainPart:GetChildren() do
		if instance:IsA("WeldConstraint") and instance.Enabled then
			instance.Enabled = false
		end
	end
end

function PieAmmo.matchAmmoSpin(self: CObjectType)
	-- Validate align orientation
	local mainPart = self.ammoMainPart
	local alignOrientation = mainPart and mainPart:FindFirstChild("AlignOrientation")
	if not (mainPart and alignOrientation and alignOrientation:IsA("AlignOrientation") and alignOrientation.Enabled) then
		return
	end

	-- Match align orientation's CFrame with main part's velocity
	local connection = RunService.Heartbeat:Connect(function()
		if mainPart and alignOrientation then
			alignOrientation.CFrame = CFrame.new(Vector3.zero, mainPart.AssemblyLinearVelocity.Unit)
		end
	end)
	table.insert(self.connections, connection)
end

function PieAmmo.onTouched(self: CObjectType, otherPart: BasePart, mainPartRelativeCFrame: CFrame)
	-- Validate touch
	if not (otherPart and otherPart.Parent) then
		return
	end

	-- Validate not stuck
	if self.isPieStuck then
		return
	end

	-- Validate unstick time
	if not (Constants.timeFunction() < self.launchStartTime + self:getUnstickPieDelay()) then
		return
	end

	-- Check for touching non-pvp character
	local touchedCharacter = AmmoUtil.getConnectedCharacter(otherPart)
	local creatorPlayer = self.ammoCreator.Value
	if creatorPlayer and creatorPlayer:IsA("Player") and touchedCharacter then
		if creatorPlayer.Character == touchedCharacter or not AmmoUtil.checkCanHitCharacter(creatorPlayer.Character, touchedCharacter) then
			-- Disable collision with character if server pie
			if not AmmoUtil.isPieAClientPie(self.ammoModel) then
				self:disablePieCollideCharacter(touchedCharacter)
			end
			return
		end
	end

	-- Validate hitting pie
	if not self:canStickTo(otherPart) then
		return
	end

	-- Validate not stuck
	if self.isPieStuck then
		return
	end
	self.isPieStuck = true

	-- Stick pie
	self:playSoundEffect("hit")
	task.defer(function()
		self:removeNoCollideConstraints()
	end)
	task.defer(function()
		self:stickPie(otherPart, mainPartRelativeCFrame)

		-- Hit character effect
		if creatorPlayer and creatorPlayer:IsA("Player") then
			local throwerCharacter = creatorPlayer.Character
			if throwerCharacter and touchedCharacter and self.ammoMainPart and self.hasHitCharacterEffect then
				if ServerPieAmmoApi then
					ServerPieAmmoApi.runPieHitCharacterEffect(throwerCharacter, touchedCharacter, self.ammoMainPart)
				end
			end
		end
	end)
end

function PieAmmo._onTouched(self: CObjectType, otherPart: BasePart)
	-- Validate not self
	if not self.ammoMainPart then
		return
	end
	if otherPart.AssemblyRootPart == self.ammoMainPart.AssemblyRootPart then
		return
	end

	-- Validate can touch
	if not otherPart.CanTouch then
		return
	end
	if not PhysicsService:CollisionGroupsAreCollidable(self.ammoMainPart.CollisionGroup, otherPart.CollisionGroup) then
		return
	end

	-- Calculate immediate offset
	local mainPartRelativeCFrame = otherPart.CFrame:ToObjectSpace(self.ammoMainPart.CFrame)

	self:onTouched(otherPart, mainPartRelativeCFrame)
end

function PieAmmo.disablePieCollideCharacter(self: CObjectType, character: Model)
	-- Validate new character
	if not character then
		return
	end
	if self.disabledCharacterCollisions[character] then
		return
	end
	local constraints = {}
	self.disabledCharacterCollisions[character] = constraints

	-- Get base parts
	local modelParts = AmmoUtil.getDescendantParts(self.ammoModel)
	local characterParts: {BasePart} = {}
	for _, part in character:GetDescendants() do
		if part:IsA("BasePart") then
			table.insert(characterParts, part)
		end
	end

	-- Get constraints folder
	local ammoModel = self.ammoModel
	local constraintsFolder = (function()
		local child = ammoModel:FindFirstChild("ConstraintsFolder")
		local result
		if not (child and child:IsA("Folder")) then
			result = Instance.new("Folder")
			result.Name = "ConstraintsFolder"
			result.Parent = ammoModel
		else
			result = child
		end
		return result
	end)()

	-- Add constraints
	for _, part0 in modelParts do
		for _, part1 in characterParts do
			task.defer(function()
				local noCollisionConstraint = Instance.new("NoCollisionConstraint")
				noCollisionConstraint.Part0 = part0
				noCollisionConstraint.Part1 = part1
				noCollisionConstraint.Parent = constraintsFolder
				table.insert(constraints, noCollisionConstraint)
			end)
		end
	end
end

function PieAmmo.playSoundEffect(self: CObjectType, soundName: SoundEffectsGetter.SoundEffectNames)
	-- Get skin
	local throwPieSkinFolder = self.ammoModel:FindFirstChild("PieSkin")
	local throwPieSkinModel = throwPieSkinFolder and throwPieSkinFolder:FindFirstChildOfClass("Model")
	local pieSkinName = throwPieSkinModel and throwPieSkinModel.Name or ""

	-- Get sound
	local soundEffects = SoundEffectsGetter.getValueAt(pieSkinName)
	local defaultSound = soundEffects[soundName]

	-- Play at main part
	local parentPart = self.ammoMainPart
	if parentPart and defaultSound and typeof(defaultSound) == "Instance" and defaultSound:IsA("Sound") then
		local newSound = defaultSound:Clone()
		newSound.PlayOnRemove = false
		newSound.Parent = self.ammoMainPart
		newSound:Play()
		newSound.Ended:Once(function()
			newSound:Destroy()
		end)
	end
end

function PieAmmo.getUnstickPieDelay(self: CObjectType)
	local unstickDelay = tonumber(self.ammoPieConfig:GetAttribute("BaseUnstickPieDelay")) or 0
	for _, delay in self.extraUnstickPieDelayConfig:GetAttributes() do
		if type(delay) == "number" then
			unstickDelay += delay
		end
	end
	return unstickDelay
end

function PieAmmo.getRemovePieDelay(self: CObjectType)
	local removeDelay = tonumber(self.ammoPieConfig:GetAttribute("BaseRemovePieDelay")) or 0
	for _, delay in self.extraRemovePieDelayConfig:GetAttributes() do
		if type(delay) == "number" then
			removeDelay += delay
		end
	end
	return removeDelay
end


--- Clean up ---

function PieAmmo.removeNoCollideConstraints(self: CObjectType)
	for _, constraints in self.disabledCharacterCollisions do
		for _, noCollisionConstraint: NoCollisionConstraint in constraints do
			noCollisionConstraint.Enabled = false
			noCollisionConstraint:Destroy()
		end
	end
	self.disabledCharacterCollisions = {}
end

function PieAmmo.removePie(self: CObjectType)
	-- Remove pie in the server
	if ServerPieAmmoApi and self.ammoMainPart then
		ServerPieAmmoApi.removeServerPie(self.ammoMainPart)
	end

	-- Remove pie in the script
	self.ammoModel:Destroy()
end

function PieAmmo.cleanup(self: CObjectType)
	self:removePie()
	for _, connection in self.connections do
		if connection.Connected then
			connection:Disconnect()
		end
	end
	table.clear(self.connections)
end

function PieAmmo.destroy(self: CObjectType)
	self:cleanup()
end


---------- Return class ----------

table.freeze(PieAmmo)
return PieAmmo
