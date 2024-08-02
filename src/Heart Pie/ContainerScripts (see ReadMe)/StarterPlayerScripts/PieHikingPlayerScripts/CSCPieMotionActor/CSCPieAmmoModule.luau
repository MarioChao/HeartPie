--!strict
-- Client-Server-Client Pie Ammo Module

-- Services

local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

-- Variables

local unstickPieTime = 7.5
local removePieTime = 12

---------- Module ----------
-- Pie Ammo Class
local PieAmmo = {}
PieAmmo.mt = {}
PieAmmo.mt.__index = PieAmmo

-- Class Attributes
function PieAmmo.new(ammoModel: Model, hasHitCharacterEffect: boolean)
	-- Constructor
	local newPieAmmo = {} :: {[string]: any}
	setmetatable(newPieAmmo, PieAmmo.mt)

	-- Ammo Info
	newPieAmmo.AmmoModel = ammoModel
	newPieAmmo.AmmoMainPart = newPieAmmo.AmmoModel:WaitForChild("MainPart") :: Part
	newPieAmmo.AmmoSounds = {
		["Fire"] = newPieAmmo.AmmoMainPart:WaitForChild("FireSound") :: Sound,
		["Hit"] = newPieAmmo.AmmoMainPart:WaitForChild("HitSound") :: Sound
	}
	newPieAmmo.AmmoInternalLaunchVelocity = newPieAmmo.AmmoModel:GetAttribute("InternalLaunchVelocity") :: Vector3
	newPieAmmo.AmmoCreator = newPieAmmo.AmmoModel:WaitForChild("Creator") :: ObjectValue
	newPieAmmo.AmmoPieSpins = newPieAmmo.AmmoModel:GetAttribute("InternalSpinByVelocity") :: boolean

	-- Variables
	newPieAmmo.pieStuck = false
	newPieAmmo.launchTime = nil :: number?
	newPieAmmo.HasHitCharacterEffect = hasHitCharacterEffect
	newPieAmmo.Connections = {} :: {RBXScriptConnection}

	-- Check valid
	local isValid = true
	if not (newPieAmmo.AmmoInternalLaunchVelocity and newPieAmmo.AmmoMainPart:FindFirstChild("PieAttachment")) then
		isValid = false
	end
	local character = newPieAmmo.AmmoCreator and newPieAmmo.AmmoCreator.Value.Character
	local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart") :: Part
	local throwDistance = humanoidRootPart and (newPieAmmo.AmmoMainPart.Position - humanoidRootPart.Position).Magnitude
	local maxThrowDistance = humanoidRootPart and (20 + humanoidRootPart.AssemblyLinearVelocity.Magnitude / 6)
	if not humanoidRootPart or (throwDistance > maxThrowDistance) then
		isValid = false
	end

	-- Return
	if not isValid then
		newPieAmmo.AmmoModel = nil
		newPieAmmo.AmmoMainPart = nil
		newPieAmmo.AmmoSounds = nil
		newPieAmmo.AmmoInternalLaunchVelocity = nil
		newPieAmmo.AmmoCreator = nil
		newPieAmmo.AmmoPieSpins = nil
	end
	return newPieAmmo
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
	self:removePie()
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
	for _, connection in self.Connections do
		if connection.Connected then
			connection:Disconnect()
			connection = nil
		end
	end
end

return PieAmmo
