--!strict
-- Client Pie Launch Script


---------- Validate container ----------

-- Under data model
if not script:FindFirstAncestorWhichIsA("DataModel") then
	return
end


---------- Services ----------

local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

---------- Imports ----------

local _PieHiking_SharedStorage = ReplicatedStorage:WaitForChild("PieHiking_SharedStorage")
local _AmmoModules = _PieHiking_SharedStorage:WaitForChild("AmmoModules")
local ClientPieAmmoApi = require(_AmmoModules:WaitForChild("ClientPieAmmoApi"))

local _Modules = _PieHiking_SharedStorage:WaitForChild("Modules")
local BelovedRemote = require(_Modules:WaitForChild("BelovedRemote"))

---------- Types ----------

type Motion = {["CFrame"]: CFrame?, ["Direction"]: Vector3?}

---------- Instances ----------

local Tool = script.Parent.Parent.Parent
local ToolEvents = Tool:WaitForChild("ToolEvents")
local PieLaunchEvent = ToolEvents:WaitForChild("PieLaunchEvent")

local PieModel = Tool:WaitForChild("PieModel")

---------- Variables ----------

local PieAmmoModel: Model
local EquippedPieSkin: Model

local launchMinIntervalSeconds = 0.7
local lastLaunchTime = os.clock() - launchMinIntervalSeconds

local printDebug = Tool:GetAttribute("_PrintDebug")

local character: Model? = nil
local player: Player? = nil

---------- Local functions ----------

local function checkLaunchMotion(player: Player, launchMotion: Motion)
	-- Validate launch motion
	local launchCFrame = launchMotion.CFrame
	local launchDirection = launchMotion.Direction
	if not (launchCFrame and launchDirection) then
		return false
	end

	-- Sanity check for launch position
	local character = player.Character
	local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart") :: Part
	local launchPosition = launchMotion.CFrame and launchMotion.CFrame.Position
	if not (humanoidRootPart and launchPosition) then
		return false
	end
	local throwDistance = (humanoidRootPart.Position - launchPosition).Magnitude
	local maxThrowDistance = 10 + humanoidRootPart.AssemblyLinearVelocity.Magnitude / 6
	if throwDistance > maxThrowDistance then
		return false
	end

	return true
end

local function onLaunchPie(caller: Player, launchMotion: Motion)
	-- Sanity check for launch motion
	if not (caller == player and checkLaunchMotion(caller, launchMotion)) then
		if printDebug then
			print("Fail check")
		end
		return
	end

	-- Sanity check for launch time
	if os.clock() - lastLaunchTime < launchMinIntervalSeconds then
		return
	end

	-- Validate ammo model
	if not PieAmmoModel then
		return
	end

	-- Calculate actual launch motion
	local launchCFrame = launchMotion.CFrame
	local launchDirection = launchMotion.Direction
	local launchOffsetStuds = Tool:GetAttribute("LaunchOffsetStuds")
	if not (launchCFrame and launchDirection) then
		warn(`[Client Pie Launch]: Incomplete launch motion data.`)
		return
	end
	launchCFrame += launchDirection.Unit * launchOffsetStuds

	-- Create Client pie's unique id
	local clientPieId = HttpService:GenerateGUID(true)

	-- Launch CSC Pie
	local finalizedLaunchMotion = {
		["CFrame"] = launchCFrame,
		["Direction"] = launchDirection,
		["Velocity"] = nil
	}
	BelovedRemote.fire_toServer("Launch CSC Pie", Tool, PieModel, finalizedLaunchMotion, clientPieId)

	-- Set up new pie ammo
	local newPieAmmoModel = PieAmmoModel:Clone()
	local newPieAmmoMainPart = newPieAmmoModel:FindFirstChild("MainPart")
	if not (newPieAmmoMainPart and newPieAmmoMainPart:IsA("BasePart")) then
		warn(`[Client Pie Launch]: No main part found for pie model.`)
		return
	end

	-- Tag the new pie ammo model
	CollectionService:AddTag(newPieAmmoModel, clientPieId)
	local uniquePieId = Instance.new("StringValue")
	uniquePieId.Name = "UniquePieId"
	uniquePieId.Value = clientPieId
	uniquePieId.Parent = newPieAmmoModel

	-- Set up pie values: launch velocity
	local launchVelocity = Tool:GetAttribute("LaunchVelocity")
	local launchVelocity_Vector3 = launchDirection.Unit * launchVelocity
	newPieAmmoModel:SetAttribute("_LaunchVelocity", launchVelocity_Vector3)

	-- Set up pie values: creator
	local newPieCreator = Instance.new("ObjectValue")
	newPieCreator.Name = "Creator"
	newPieCreator.Value = caller
	newPieCreator.Parent = newPieAmmoModel

	-- Set up pie values: booleans
	local pieSpinByVelocity = Tool:GetAttribute("PieSpinByVelocity")
	newPieAmmoModel:SetAttribute("_SpinByVelocity", pieSpinByVelocity)
	local canOverlapPart = Tool:GetAttribute("CanOverlapPart")
	newPieAmmoModel:SetAttribute("_CanOverlapPart", canOverlapPart)
	local canCollideThrower = Tool:GetAttribute("CanCollideThrower")
	newPieAmmoModel:SetAttribute("_CanCollideThrower", canCollideThrower)

	-- Set up pie align orientation
	local pieAlignSpin = Tool:GetAttribute("PieAlignSpin")
	local newPieAlignOrientation = newPieAmmoMainPart:FindFirstChild("AlignOrientation")
	if not (newPieAlignOrientation and newPieAlignOrientation:IsA("AlignOrientation")) then
		warn(`[Client Pie Launch]: No align orientation found for pie model.`)
		return
	end
	newPieAlignOrientation.CFrame = CFrame.new(Vector3.zero, launchDirection.Unit)
	newPieAlignOrientation.Enabled = pieAlignSpin

	-- Set up pie ammo position
	newPieAmmoModel.Parent = workspace
	newPieAmmoMainPart:PivotTo(launchCFrame)
	newPieAmmoMainPart.Anchored = false

	-- Launch pie
	lastLaunchTime = os.clock()
	ClientPieAmmoApi.createAndLaunch(newPieAmmoModel)
end

local function createPieAmmoModel()
	-- Validate pie skin folder
	if not PieModel:FindFirstChild("PieSkin") then
		return
	end

	-- Clone the pie model
	local pieAmmoModel = PieModel:Clone()
	local pieAmmoMainPart = pieAmmoModel:FindFirstChild("MainPart")
	local pieAttachment = pieAmmoMainPart and pieAmmoMainPart:FindFirstChild("PieAttachment")
	local rigidConstraint = pieAmmoMainPart and pieAmmoMainPart:FindFirstChild("RigidConstraint")
	local upwardsForce = pieAmmoMainPart and pieAmmoMainPart:FindFirstChild("UpwardsForce")

	-- Set up objects
	for _, part in pieAmmoModel:GetDescendants() do
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
	if rigidConstraint then
		rigidConstraint.Enabled = false
	end
	if upwardsForce then
		upwardsForce.Enabled = true
	end

	-- Update pie ammo model
	if PieAmmoModel then
		Debris:AddItem(PieAmmoModel, 0)
	end
	PieAmmoModel = pieAmmoModel
end

local function onEquipped()
	character = Tool.Parent
	player = character and Players:GetPlayerFromCharacter(character)

	createPieAmmoModel()
end

local function onUnequipped()
	character = nil
	player = nil
end

local function onPieSkinChange()
	-- Wait a frame to allow skin to change
	task.wait()
	createPieAmmoModel()
end

---------- Event functions ----------

local function onPieLaunchEvent(mode: string, ...)
	if mode == "Launch Pie" then
		onLaunchPie(Players.LocalPlayer, ...)
	end
end

---------- Calling / connecting functions ----------

PieLaunchEvent.Event:Connect(onPieLaunchEvent)
Tool.Equipped:Connect(onEquipped)
Tool.Unequipped:Connect(onUnequipped)
PieModel:GetAttributeChangedSignal("EquippedSkinId"):Connect(onPieSkinChange)
task.defer(function()
	while not PieModel:FindFirstChild("PieSkin") do
		task.wait(0.05)
	end
	createPieAmmoModel()
end)
