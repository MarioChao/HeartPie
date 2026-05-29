--!strict

-- Client-Server-Client Pie Ammo Class


---------- Services ----------

local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")


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
	ammoSounds: {Sound},
	ammoInternalLaunchVelocity: Vector3,
	ammoCreator: ObjectValue,
	ammoPieSpins: boolean,

	isPieStuck: boolean,
	launchStartTime: number,
	hasHitCharacterEffect: boolean,
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
	else
		self.ammoSounds = {}
	end
	self.ammoInternalLaunchVelocity = self.ammoModel:GetAttribute("_LaunchVelocity") :: Vector3
	self.ammoCreator = self.ammoModel:WaitForChild("Creator") :: ObjectValue
	self.ammoPieSpins = self.ammoModel:GetAttribute("_SpinByVelocity") :: boolean

	-- Variables
	self.isPieStuck = false
	self.launchStartTime = 0
	self.hasHitCharacterEffect = hasHitCharacterEffect
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

function PieAmmo.launchPie(self: CObjectType)
	-- Validate ammo
	if not (self.ammoMainPart and self.isValid) then
		return
	end

	-- Configure and shoot pie with initial velocity
	self.launchStartTime = Constants.timeFunction()
	-- Check if ammo is not stuck before giving velocity
	local ammoMainPart = self.ammoMainPart :: Part
	local ammoAssemblyRootPart = ammoMainPart.AssemblyRootPart
	if ammoAssemblyRootPart and ammoAssemblyRootPart:IsDescendantOf(self.ammoModel) then
		self.ammoMainPart.AssemblyLinearVelocity = self.ammoInternalLaunchVelocity
	end
	if self.ammoPieSpins then
		self:matchAmmoSpin()
	end

	-- Unstick
	task.wait(Constants.baseUnstickPieTime + self.launchStartTime - Constants.timeFunction())
	self:unstickPie()

	-- Remove
	task.wait(Constants.baseRemovePieTime + self.launchStartTime - Constants.timeFunction())
	self:cleanup()
end

function PieAmmo.unstickPie(self: CObjectType)
	-- Validate ammo
	if not (self.ammoMainPart and self.isValid) then
		return
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
	local mainPart = self.ammoMainPart :: Part
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


--- Clean up ---

function PieAmmo.removePie(self: CObjectType)
	-- Remove pie in the script
	Debris:AddItem(self.ammoModel, 0)
end

function PieAmmo.cleanup(self: CObjectType)
	self:removePie()
	for _, connection in self.connections do
		if connection then
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
