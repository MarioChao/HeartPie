--!strict

-- Client-Server-Client Pie Ammo Class


---------- Services ----------

local RunService = game:GetService("RunService")


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

	ammoPieConfig: Configuration,
	extraUnstickPieDelayConfig: Configuration,
	extraRemovePieDelayConfig: Configuration,
	ammoPieStates: Configuration,

	isPieStuck: boolean,
	launchStartTime: number,
	hasHitCharacterEffect: boolean,
	connections: {RBXScriptConnection},
}

export type CObjectType = typeof(setmetatable({} :: CFieldData, PieAmmo))


----- Class fields -----

--- Constructor ---

function PieAmmo.new(ammoModel: Model)
	local self = setmetatable({}, PieAmmo) :: CObjectType

	-- Ammo Info
	self.ammoModel = ammoModel
	self.ammoMainPart = self.ammoModel:WaitForChild("MainPart") :: BasePart
	self.ammoInternalLaunchVelocity = self.ammoModel:GetAttribute("_LaunchVelocity") :: Vector3
	self.ammoCreator = self.ammoModel:WaitForChild("Creator") :: ObjectValue
	self.ammoPieSpins = self.ammoModel:GetAttribute("_SpinByVelocity") :: boolean

	-- Values
	local pieValues = self.ammoModel:WaitForChild("PieValues") :: Folder
	self.ammoPieConfig = pieValues:WaitForChild("PieConfig") :: Configuration
	self.extraUnstickPieDelayConfig = self.ammoPieConfig:WaitForChild("ExtraUnstickPieDelay") :: Configuration
	self.extraRemovePieDelayConfig = self.ammoPieConfig:WaitForChild("ExtraRemovePieDelay") :: Configuration
	self.ammoPieStates = pieValues:WaitForChild("PieStates") :: Configuration

	-- Variables
	self.isPieStuck = false
	self.launchStartTime = 0
	self.hasHitCharacterEffect = false
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
			if not (humanoidRootPart and throwDistance <= maxThrowDistance) then
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
	self.ammoMainPart.Massless = false
	self.launchStartTime = Constants.timeFunction()
	self.ammoPieStates:SetAttribute("LaunchStartTime", self.launchStartTime)

	-- Check if ammo is not stuck before giving velocity
	local ammoMainPart = self.ammoMainPart
	local ammoAssemblyRootPart = ammoMainPart.AssemblyRootPart
	if ammoAssemblyRootPart and ammoAssemblyRootPart:IsDescendantOf(self.ammoModel) then
		self.ammoMainPart.AssemblyLinearVelocity = self.ammoInternalLaunchVelocity
	end
	if self.ammoPieSpins then
		self:matchAmmoSpin()
	end

	-- Unstick
	while true do
		if Constants.timeFunction() >= self.launchStartTime + self:getUnstickPieDelay() then
			break
		end
		task.wait()
	end
	self:unstickPie()

	-- Remove
	while true do
		if Constants.timeFunction() >= self.launchStartTime + self:getRemovePieDelay() then
			break
		end
		task.wait()
	end
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

function PieAmmo.removePie(self: CObjectType)
	-- Remove pie in the script
	self.ammoModel:Destroy()
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
