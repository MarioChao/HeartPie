--!strict
-- Server Pie Launch Script

---------- Services ----------

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

---------- Types ----------

type Motion = {["CFrame"]: CFrame?, ["Direction"]: Vector3?}

---------- Instances ----------
local Tool = script.Parent.Parent.Parent
local ToolEvents = Tool:WaitForChild("ToolEvents")
local PieLaunchRemoteEvent = ToolEvents:WaitForChild("PieLaunchRemoteEvent")

local PieModel = Tool:WaitForChild("PieModel")

local PieHikingEvents = ReplicatedStorage:WaitForChild("PieHikingEvents") :: Folder
local PieHikeBindable = PieHikingEvents:WaitForChild("PieHikeBindable") :: BindableEvent

---------- Variables ----------

local PieAmmoModel: Model
local EquippedPieSkin: Model

local launchMinIntervalSeconds = 0.7
local lastLaunchTime = os.clock() - launchMinIntervalSeconds
local pieAmmoMaxSeconds = 12

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
	task.desynchronize()
	if not (caller == player and checkLaunchMotion(caller, launchMotion)) then
		if printDebug then
			print("Fail check")
		end
		return
	end

	-- Sanity check for Client pies
	local isClientPieType = Tool:GetAttribute("IsClientPieType")
	if isClientPieType then
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
	local launchCFrame = launchMotion.CFrame :: CFrame
	local launchDirection = launchMotion.Direction :: Vector3
	local launchOffsetStuds = Tool:GetAttribute("LaunchOffsetStuds")
	launchCFrame += launchDirection.Unit * launchOffsetStuds

	-- Setup new pie ammo
	task.synchronize()
	local newPieAmmoModel = PieAmmoModel:Clone()
	local newPieAmmoMainPart = newPieAmmoModel:FindFirstChild("MainPart") :: Part

	-- Setup pie values
	local launchVelocity = Tool:GetAttribute("LaunchVelocity")
	local launchVelocity_Vector3 = launchDirection.Unit * launchVelocity
	newPieAmmoModel:SetAttribute("_LaunchVelocity", launchVelocity_Vector3)
	local newPieCreator = Instance.new("ObjectValue")
	newPieCreator.Name = "Creator"
	newPieCreator.Value = player
	newPieCreator.Parent = newPieAmmoModel
	local pieSpinByVelocity = Tool:GetAttribute("PieSpinByVelocity")
	newPieAmmoModel:SetAttribute("_SpinByVelocity", pieSpinByVelocity)
	local canOverlapPart = Tool:GetAttribute("CanOverlapPart")
	newPieAmmoModel:SetAttribute("_CanOverlapPart", canOverlapPart)

	-- Setup pie align orientation
	local pieAlignSpin = Tool:GetAttribute("PieAlignSpin")
	local newPieAlignOrientation = newPieAmmoMainPart:FindFirstChild("AlignOrientation") :: AlignOrientation
	newPieAlignOrientation.CFrame = CFrame.new(Vector3.zero, launchDirection.Unit)
	newPieAlignOrientation.Enabled = pieAlignSpin

	-- Setup pie ammo position
	newPieAmmoModel.Parent = workspace -- Might cause exception
	newPieAmmoMainPart:PivotTo(launchCFrame)
	newPieAmmoMainPart.Anchored = false
	newPieAmmoMainPart.CanCollide = true
	newPieAmmoMainPart:SetNetworkOwner(nil)

	-- Launch pie
	lastLaunchTime = os.clock()
	PieHikeBindable:Fire("Start Launch", newPieAmmoModel, player)

	-- Remove pie after a while
	Debris:AddItem(newPieAmmoModel, 12)
end

local function createPieAmmoModel()
	-- Validate pie skin folder
	if not PieModel:FindFirstChild("PieSkin") then
		return
	end

	-- Clone the pie model
	local pieAmmoModel = PieModel:Clone()
	local pieAmmoMainPart = pieAmmoModel:FindFirstChild("MainPart") :: Part
	local pieAttachment = pieAmmoMainPart and pieAmmoMainPart:FindFirstChild("PieAttachment") :: Attachment
	local rigidConstraint = pieAmmoMainPart and pieAmmoMainPart:FindFirstChild("RigidConstraint") :: RigidConstraint
	local upwardsForce = pieAmmoMainPart and pieAmmoMainPart:FindFirstChild("UpwardsForce") :: VectorForce

	-- Set up objects
	for _, part in pieAmmoModel:GetDescendants() do
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
	task.wait(0.03)
	createPieAmmoModel()
end

---------- Event functions ----------

local function onPieLaunchServerEvent(player: Player, mode: string, ...)
	if mode == "Launch Pie" then
		onLaunchPie(player, ...)
	end
end

---------- Calling / connecting functions ----------

PieLaunchRemoteEvent.OnServerEvent:Connect(onPieLaunchServerEvent)
Tool.Equipped:Connect(onEquipped)
Tool.Unequipped:Connect(onUnequipped)
PieModel:GetAttributeChangedSignal("EquippedSkinId"):Connect(onPieSkinChange)
task.defer(function()
	while not PieModel:FindFirstChild("PieSkin") do
		task.wait(0.05)
	end
	createPieAmmoModel()
end)
