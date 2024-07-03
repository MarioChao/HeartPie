--!strict
-- Client-Server-Client Pie Event Script

-- Tool info
local Tool = script.Parent.Parent.Parent
local ToolEvents = Tool:WaitForChild("ToolEvents")
local CSCPieLaunchRemoteEvent = ToolEvents:WaitForChild("CSCPieLaunchRemoteEvent")

local PieModel = Tool:WaitForChild("PieModel")

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Types
type FinalizedMotion = {["CFrame"]: CFrame?, ["Direction"]: Vector3?, ["Velocity"]: number?}

-- Instances
local PieHikingEvents = ReplicatedStorage:WaitForChild("PieHikingEvents") :: Folder
local CSCPieRemoteEvent = PieHikingEvents:WaitForChild("CSCPieRemoteEvent") :: RemoteEvent

-- Variables
local launchMinIntervalSeconds = 0.7
local lastLaunchTime = os.clock() - launchMinIntervalSeconds

local character: Model? = nil
local player: Player? = nil

-- Functions
local function checkFinalizedLaunchMotion(player: Player, launchMotion: FinalizedMotion): boolean
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
	local launchOffsetStuds = Tool:GetAttribute("LaunchOffsetStuds")
	local maxThrowDistance = 10 + humanoidRootPart.AssemblyLinearVelocity.Magnitude / 6 + math.abs(launchOffsetStuds)
	if throwDistance > maxThrowDistance then
		return false
	end

	return true
end

local function onLaunchCSCPie(caller: Player, launchMotion: FinalizedMotion, clientPieId: string)
	-- Sanity check for launch motion
	if not (caller == player and checkFinalizedLaunchMotion(caller, launchMotion)) then
		return
	end

	-- Sanity check for launch time
	if os.clock() - lastLaunchTime < launchMinIntervalSeconds then
		return
	end
	
	-- Validate and add velocity to launch direction
	local launchVelocity = Tool:GetAttribute("LaunchVelocity")
	if not launchVelocity then
		return
	end
	launchMotion["Velocity"] = launchVelocity

	-- Fire event for CSC Pie
	local canCollide = false
	local transparency = Tool:GetAttribute("NoCollideTransparency")
	local pieAlignSpin = Tool:GetAttribute("PieAlignSpin")
	local pieSpinByVelocity = Tool:GetAttribute("PieSpinByVelocity")
	local pieSpinInfo = {
		["AlignSpin"] = pieAlignSpin,
		["ByVelocity"] = pieSpinByVelocity
	}
	fireOtherClients(caller, "Launch CSC Pie", caller, launchMotion, canCollide, transparency, clientPieId, PieModel, pieSpinInfo)
end

local function onStickCSCPieToPart(caller: Player, throwPieId: string, hitPart: BasePart?, hitCFrame: CFrame, relativeCFrame: CFrame)
	-- Sanity check for player
	if not (caller == player) then
		return
	end
	
	-- More checks on the other side
	fireOtherClients(caller, "Stick CSC Pie To Part", throwPieId, hitPart, hitCFrame, relativeCFrame)
end

local function onStickCSCPieToCSCPie(caller: Player, throwPieId: string, hitPieId: string, hitCFrame: CFrame, relativeCFrame: CFrame)
	-- Sanity check for player
	if not (caller == player) then
		return
	end
	
	-- More checks on the other side
	fireOtherClients(caller, "Stick CSC Pie To CSC Pie", throwPieId, hitPieId, hitCFrame, relativeCFrame)
end

-- Event functions
function fireOtherClients(except: Player, ...)
	for _, otherPlayer in Players:GetPlayers() do
		if otherPlayer ~= except then
			CSCPieRemoteEvent:FireClient(otherPlayer, ...)
		end
	end
end

local function onCSCPieLaunchServerEvent(caller: Player, mode: string, ...)
	if mode == "Launch CSC Pie" then
		onLaunchCSCPie(caller, ...)
	end
end

local function onCSCPieServerEvent(caller: Player, mode: string, ...)
	if mode == "Stick CSC Pie To Part" then
		onStickCSCPieToPart(caller, ...)
	elseif mode == "Stick CSC Pie To CSC Pie" then
		onStickCSCPieToCSCPie(caller, ...)
	end
end

local function onEquipped()
	character = Tool.Parent
	player = character and Players:GetPlayerFromCharacter(character)
end

local function onUnequipped()
	character = nil
	player = nil
end

-- Calling / connection functions
CSCPieLaunchRemoteEvent.OnServerEvent:Connect(onCSCPieLaunchServerEvent)
CSCPieRemoteEvent.OnServerEvent:Connect(onCSCPieServerEvent)
Tool.Equipped:Connect(onEquipped)
Tool.Unequipped:Connect(onUnequipped)
