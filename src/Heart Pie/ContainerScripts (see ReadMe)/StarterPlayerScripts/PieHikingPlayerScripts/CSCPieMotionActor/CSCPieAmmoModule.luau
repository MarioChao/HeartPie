--!strict
-- Client-Server-Client Pie Ammo Module

---------- Module ----------
local PieAmmo = {}
PieAmmo.__index = PieAmmo

---------- Services ----------

local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

---------- Variables ----------

local unstickPieTime = 7.5
local removePieTime = 12

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
	end
	return self
end

-- Functions

function PieAmmo:unstickPie()
	-- Validate ammo main part
	if not self.AmmoMainPart then
		return
	end

	-- Unstick pie in the script
	for _, instance in self.AmmoMainPart:GetChildren() do
		if instance:IsA("WeldConstraint") and instance.Enabled then
			instance.Enabled = false
		end
	end
end

function PieAmmo:removePie()
	-- Remove pie in the script
	Debris:AddItem(self.AmmoModel, 0)
end

function PieAmmo:launchPie()
	-- Validate ammo main part
	if not self.AmmoMainPart then
		return
	end

	-- Configure and shoot pie with initial velocity
	self.launchTime = os.clock()
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
