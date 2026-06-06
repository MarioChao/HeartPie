--!strict

-- Client Pie Launch


---------- Validate container ----------

-- Under data model (for plugin)
if not script:FindFirstAncestorWhichIsA("DataModel") then
	return
end


---------- Services ----------

local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")


---------- Imports ----------

local _PieHiking_SharedStorage = ReplicatedStorage:WaitForChild("PieHiking_SharedStorage")
local _AmmoModules = _PieHiking_SharedStorage:WaitForChild("AmmoModules")
local ClientPieAmmoApi = require(_AmmoModules:WaitForChild("ClientPieAmmoApi"))

local _Modules = _PieHiking_SharedStorage:WaitForChild("Modules")
local BelovedRemote = require(_Modules:WaitForChild("BelovedRemote"))

local _ToolScripts = script.Parent.Parent.Parent
local Tooling = require(_ToolScripts:WaitForChild("Tooling"))


---------- Types ----------

type Motion = {["CFrame"]: CFrame?, ["Direction"]: Vector3?}


---------- Constants ----------

local Constants = {}

Constants.apiBindableEvent = script.Parent:WaitForChild("ApiBindableEvent")

Constants.localPlayer = Players.LocalPlayer

Constants.timeFunction = time

table.freeze(Constants)


---------- Globals ----------

local Globals = {}

Globals.pieAmmoModel = nil :: Model?

Globals.lastLaunchTime = Constants.timeFunction() - 1


---------- Local functions ----------

local checkLaunchMotion
local onLaunchPie

local createPieAmmoModel


----- Launch pie -----

checkLaunchMotion = function(player: Player, launchMotion: Motion)
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

onLaunchPie = function(caller: Player, launchMotion: Motion)
	-- Check equipped
	if not Tooling.getIsEquipped() then
		return
	end

	-- Sanity check for launch motion
	if not (caller == Tooling.getOwner() and checkLaunchMotion(caller, launchMotion)) then
		return
	end

	-- Sanity check for launch time
	local currentTime = Constants.timeFunction()
	local launchMinInterval = Tooling.configs.getDurationThrow() + Tooling.configs.getDurationReload() - 0.4
	if currentTime - Globals.lastLaunchTime < launchMinInterval then
		return
	end

	-- Validate ammo model
	createPieAmmoModel()
	if not Globals.pieAmmoModel then
		return
	end

	-- Calculate actual launch motion
	local launchCFrame = launchMotion.CFrame
	local launchDirection = launchMotion.Direction
	local launchOffsetStuds = Tooling.configs.getLaunchOffsetStuds()
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
	BelovedRemote.fire_toServer("Launch CSC Pie", Tooling.tool, Tooling.pieModel, finalizedLaunchMotion, clientPieId)

	-- Set up new pie ammo
	local newPieAmmoModel = Globals.pieAmmoModel:Clone()
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
	local launchVelocity = Tooling.configs.getLaunchVelocity()
	local launchVelocity_Vector3 = launchDirection.Unit * launchVelocity
	newPieAmmoModel:SetAttribute("_LaunchVelocity", launchVelocity_Vector3)

	-- Set up pie values: creator
	local newPieCreator = Instance.new("ObjectValue")
	newPieCreator.Name = "Creator"
	newPieCreator.Value = caller
	newPieCreator.Parent = newPieAmmoModel

	-- Set up pie values: booleans
	local pieSpinByVelocity = Tooling.configs.getPieSpinByVelocity()
	newPieAmmoModel:SetAttribute("_SpinByVelocity", pieSpinByVelocity)
	local canOverlapPart = Tooling.configs.getCanOverlapPart()
	newPieAmmoModel:SetAttribute("_CanOverlapPart", canOverlapPart)
	local canCollideThrower = Tooling.configs.getCanCollideThrower()
	newPieAmmoModel:SetAttribute("_CanCollideThrower", canCollideThrower)

	-- Set up pie align orientation
	local pieAlignSpin = Tooling.configs.getPieAlignSpin()
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
	Globals.lastLaunchTime = currentTime
	ClientPieAmmoApi.createAndLaunch(newPieAmmoModel)
end


----- Refresh model -----

createPieAmmoModel = function()
	-- Validate pie skin folder
	if not Tooling.pieModel:FindFirstChild("PieSkin") then
		return
	end

	-- Clone the pie model
	local pieAmmoModel = Tooling.pieModel:Clone()
	local pieAmmoMainPart = pieAmmoModel:FindFirstChild("MainPart")
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
	else
		warn(`[Client Pie Launch]: No rigid constraint found.`)
	end
	if upwardsForce then
		upwardsForce.Enabled = true
	else
		warn(`[Client Pie Launch]: No upwards force found.`)
	end

	-- Update pie ammo model
	if Globals.pieAmmoModel then
		Globals.pieAmmoModel:Destroy()
	end
	Globals.pieAmmoModel = pieAmmoModel
end


----- Main -----

local function main()
	Constants.apiBindableEvent.Event:Connect(function(mode: string, ...)
		if mode == "Launch Client Pie" then
			onLaunchPie(Constants.localPlayer, ...)
		end
	end)
end


---------- Calling function ----------

main()
