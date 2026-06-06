--!strict

-- Client-Server-Client Pie Event


---------- Validate container ----------

-- Server script service
if not script:FindFirstAncestorWhichIsA("ServerScriptService") then
	return
end


---------- Services ----------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")


---------- Imports ----------

local _PieHiking_SharedStorage = ReplicatedStorage:WaitForChild("PieHiking_SharedStorage")
local _Modules = _PieHiking_SharedStorage:WaitForChild("Modules")
local BelovedRemote = require(_Modules:WaitForChild("BelovedRemote"))


---------- Types ----------

type FinalizedMotion = {
	CFrame: CFrame?,
	Direction: Vector3?,
	Velocity: number?,
}


---------- Local functions ----------

local checkFinalizedLaunchMotion

local onLaunchCSCPie
local onStickCSCPieToPart
local onStickCSCPieToCSCPie

local fireOtherClients: (except: Player, actionName: string, ...any) -> ()


----- Checks -----

checkFinalizedLaunchMotion = function(tool: Tool, player: Player, launchMotion: FinalizedMotion): boolean
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
	local _toolValues = tool:FindFirstChild("ToolValues")
	local _toolConfig = _toolValues and _toolValues:FindFirstChild("ToolConfig")
	local launchOffsetStuds = _toolConfig and tonumber(_toolConfig:GetAttribute("LaunchOffsetStuds"))
	if not launchOffsetStuds then
		return false
	end
	local maxThrowDistance = 10 + humanoidRootPart.AssemblyLinearVelocity.Magnitude / 6 + math.abs(launchOffsetStuds)
	if throwDistance > maxThrowDistance then
		return false
	end

	return true
end


----- Pie functions -----

onLaunchCSCPie = function(caller: Player, tool: Tool, pieModel: Model, launchMotion: FinalizedMotion, clientPieId: string)
	-- Validate model
	if not pieModel:IsDescendantOf(tool) then
		return
	end

	-- Sanity check for launch motion
	if not checkFinalizedLaunchMotion(tool, caller, launchMotion) then
		return
	end

	-- Validate tool config
	local _toolValues = tool:FindFirstChild("ToolValues")
	local _toolConfig = _toolValues and _toolValues:FindFirstChild("ToolConfig")
	if not _toolConfig then
		return
	end

	-- Validate and add velocity to launch direction
	local launchVelocity = tonumber(_toolConfig:GetAttribute("LaunchVelocity"))
	if not launchVelocity then
		return
	end
	launchMotion["Velocity"] = launchVelocity

	-- Fire event for CSC Pie
	local canCollide = false
	local transparency = _toolConfig:GetAttribute("NoCollideTransparency")
	local pieAlignSpin = _toolConfig:GetAttribute("PieAlignSpin")
	local pieSpinByVelocity = _toolConfig:GetAttribute("PieSpinByVelocity")
	local pieSpinInfo = {
		["AlignSpin"] = pieAlignSpin,
		["ByVelocity"] = pieSpinByVelocity
	}
	fireOtherClients(caller, "Launch CSC Pie", caller, launchMotion, canCollide, transparency, clientPieId, pieModel, pieSpinInfo)
end

onStickCSCPieToPart = function(caller: Player, throwPieId: string, hitPart: BasePart?, hitCFrame: CFrame, relativeCFrame: CFrame)
	-- More checks on the other side
	fireOtherClients(caller, "Stick CSC Pie To Part", throwPieId, hitPart, hitCFrame, relativeCFrame)
end

onStickCSCPieToCSCPie = function(caller: Player, throwPieId: string, hitPieId: string, hitCFrame: CFrame, relativeCFrame: CFrame)
	-- More checks on the other side
	fireOtherClients(caller, "Stick CSC Pie To CSC Pie", throwPieId, hitPieId, hitCFrame, relativeCFrame)
end


----- Remote event -----

fireOtherClients = function(except: Player, actionName: string, ...)
	for _, otherPlayer in Players:GetPlayers() do
		if otherPlayer ~= except then
			BelovedRemote.fire_toClient(actionName, otherPlayer, ...)
		end
	end
end


----- Main -----

local function main()
	-- CSC Pie
	BelovedRemote.connect_toServer("Launch CSC Pie", onLaunchCSCPie)
	BelovedRemote.connect_toServer("Stick CSC Pie To Part", onStickCSCPieToPart)
	BelovedRemote.connect_toServer("Stick CSC Pie To CSC Pie", onStickCSCPieToCSCPie)
end


---------- Calling function ----------

main()
