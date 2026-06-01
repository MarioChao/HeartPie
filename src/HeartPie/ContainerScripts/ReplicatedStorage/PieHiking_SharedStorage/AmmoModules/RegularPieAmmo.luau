--!strict

-- Regular Pie Ammo Class


---------- Services ----------

local Debris = game:GetService("Debris")
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

local ServerPieAmmoApi
if RunService:IsServer() then
	local ServerScriptService = game:GetService("ServerScriptService")
	local _PieHiking_ServerScripts = ServerScriptService:WaitForChild("PieHiking_ServerScripts")
	local _ServerAmmoModules = _PieHiking_ServerScripts:WaitForChild("ServerAmmoModules")
	ServerPieAmmoApi = require(_ServerAmmoModules:WaitForChild("ServerPieAmmoApi"))
end


---------- Constants ----------

local Constants = {}

Constants.baseUnstickPieTime = 7.5
Constants.baseRemovePieTime = 12

Constants.timeFunction = time

table.freeze(Constants)


---------- Class ----------

local PieAmmo = {}
PieAmmo.__index = PieAmmo


----- Class types -----

type CFieldData = {
	isValid: boolean,

	ammoModel: Model,
	ammoMainPart: Part?,
	ammoSounds: {
		Fire: Sound,
		Hit: Sound,
	},
	ammoInternalLaunchVelocity: Vector3,
	ammoCreator: ObjectValue,
	ammoPieSpins: boolean,
	ammoCanOverlapPart: boolean,

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
	self.ammoMainPart = self.ammoModel:WaitForChild("MainPart") :: Part
	if self.ammoMainPart then
		self.ammoSounds = {
			["Fire"] = self.ammoMainPart:WaitForChild("FireSound") :: Sound,
			["Hit"] = self.ammoMainPart:WaitForChild("HitSound") :: Sound
		}
	end
	self.ammoInternalLaunchVelocity = self.ammoModel:GetAttribute("_LaunchVelocity") :: Vector3
	self.ammoCreator = self.ammoModel:WaitForChild("Creator") :: ObjectValue
	self.ammoPieSpins = self.ammoModel:GetAttribute("_SpinByVelocity") :: boolean
	self.ammoCanOverlapPart = self.ammoModel:GetAttribute("_CanOverlapPart") :: boolean

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

function PieAmmo.setupAmmo(self: CObjectType)
	-- Validate ammo model
	if not self.ammoModel then
		return
	end
	self.launchStartTime = Constants.timeFunction()

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
end

function PieAmmo.launchPie(self: CObjectType)
	-- Validate ammo main part
	if not self.ammoMainPart then
		print(`[Regular Pie Ammo]: not main part.`)
		return
	end

	-- Configure and shoot pie with initial velocity
	self.launchStartTime = Constants.timeFunction()
	self.ammoSounds.Fire:Play()

	-- Check if ammo is not stuck before giving velocity
	local ammoMainPart = self.ammoMainPart :: Part
	local ammoAssemblyRootPart = ammoMainPart.AssemblyRootPart
	if ammoAssemblyRootPart and ammoAssemblyRootPart:IsDescendantOf(self.ammoModel) then
		self.ammoMainPart.AssemblyLinearVelocity = self.ammoInternalLaunchVelocity
	end

	-- Align pie spin
	if self.ammoPieSpins then
		self:matchAmmoSpin()
	end

	-- Unstick seconds after launch
	local timeUntilUnstick = self.ammoModel:FindFirstChild("TimeUntilUnstick")
	while self.launchStartTime + Constants.baseUnstickPieTime > Constants.timeFunction() do
		if timeUntilUnstick and timeUntilUnstick:IsA("NumberValue") then
			timeUntilUnstick.Value = self.launchStartTime + Constants.baseUnstickPieTime - Constants.timeFunction()
		end
		task.wait()
	end
	self:unstickPie()

	-- Remove seconds after launch
	task.wait(Constants.baseRemovePieTime + self.launchStartTime - Constants.timeFunction())
	self:cleanup()
end

function PieAmmo.canStickTo(self: CObjectType, hitPart: BasePart): boolean
	-- Check if the current pie is a Client pie
	local uniquePieId = self.ammoModel:FindFirstChild("UniquePieId") :: StringValue
	local pieTag = uniquePieId and uniquePieId.Value
	local isThrowClientPie = pieTag

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

	-- Quick validation
	local creatorPlayer = self.ammoCreator.Value :: Player
	local throwerCharacter = creatorPlayer.Character
	local throwPieModel = self.ammoModel
	local creatorObjectValue = throwPieModel and throwPieModel:FindFirstChild("Creator") :: ObjectValue
	local creator = creatorObjectValue and creatorObjectValue.Value :: Player
	if not (creator and throwerCharacter == creator.Character and throwerCharacter and throwerCharacter:IsA("Model")) then
		return
	end

	-- Get parameters
	local throwPieMainPart = self.ammoMainPart
	local param: PieHitEffectsGetter.EffectParameter = {
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
	local hitPieMainPart = hitPieModel and hitPieModel:FindFirstChild("MainPart") :: Part
	local hitPieUniqueId = hitPieModel and hitPieModel:FindFirstChild("UniquePieId") :: StringValue
	local hitPieTag = hitPieUniqueId and hitPieUniqueId.Value
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
		local uniquePieId = self.ammoModel:FindFirstChild("UniquePieId") :: StringValue
		local pieTag = uniquePieId and uniquePieId.Value

		-- Check if hit part is a Client or CSC pie
		if not (hitPieMainPart and isHitClientPie) then
			--[[ Hit a non-Client-pie or non-CSC-pie part ]]
			BelovedRemote.fire_toServer("Stick CSC Pie To Part", pieTag, hitPart, hitPart.CFrame, relativeCFrame)
		else
			--[[ Hit a Client pie or CSC pie ]]
			relativeCFrame = hitPieMainPart.CFrame:ToObjectSpace(self.ammoMainPart.CFrame)
			BelovedRemote.fire_toServer("Stick CSC Pie To CSC Pie", pieTag, hitPieTag, hitPieMainPart.CFrame, relativeCFrame)
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
	local upwardsForce = mainPart:FindFirstChild("UpwardsForce") :: VectorForce
	if upwardsForce then
		upwardsForce.Enabled = false
	end
	local alignOrientation = mainPart:FindFirstChild("AlignOrientation") :: AlignOrientation
	if alignOrientation then
		alignOrientation.Enabled = false
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
	if not (Constants.timeFunction() - self.launchStartTime <= Constants.baseUnstickPieTime) then
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

	-- Stick pie
	if self.isPieStuck then
		return
	end
	self.isPieStuck = true
	self.ammoSounds.Hit:Play()
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


--- Clean up ---

function PieAmmo.removeNoCollideConstraints(self: CObjectType)
	for _, constraints in self.disabledCharacterCollisions do
		for _, noCollisionConstraint: NoCollisionConstraint in constraints do
			noCollisionConstraint.Enabled = false
			Debris:AddItem(noCollisionConstraint, 0)
		end
	end
	self.disabledCharacterCollisions = {}
end

function PieAmmo.removePie(self: CObjectType)
	-- Validate ammo model
	if not self.ammoModel then
		return
	end

	-- Remove pie in the server
	if ServerPieAmmoApi and self.ammoMainPart then
		ServerPieAmmoApi.removeServerPie(self.ammoMainPart)
	end

	-- Remove pie in the script
	Debris:AddItem(self.ammoModel, 0)
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
