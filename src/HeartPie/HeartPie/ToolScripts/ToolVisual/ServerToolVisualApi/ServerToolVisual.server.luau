--!strict

-- Server Tool Visual


---------- Services ----------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")


---------- Imports ----------

local _PieHiking_ServerScripts = ServerScriptService:WaitForChild("PieHiking_ServerScripts")
local _SkinModules = _PieHiking_ServerScripts:WaitForChild("SkinModules")
local SkinUtil = require(_SkinModules:WaitForChild("SkinUtil"))

local _PieHiking_SharedStorage = ReplicatedStorage:WaitForChild("PieHiking_SharedStorage")
local _Modules = _PieHiking_SharedStorage:WaitForChild("Modules")
local BelovedRemote = require(_Modules:WaitForChild("BelovedRemote"))

local _ToolScripts = script.Parent.Parent.Parent
local Tooling = require(_ToolScripts:WaitForChild("Tooling"))


---------- Constants ----------

local Constants = {}

Constants.apiBindableEvent = script.Parent:WaitForChild("ApiBindableEvent")

table.freeze(Constants)


---------- Globals ----------

local Globals = {}

Globals.currentTransparency = nil :: number?


---------- Local functions ----------

local checkPlayerAlive

local setPieModelTransparency
local renewPieModelTransparency
local recordOriginalProperties

local setUpPieSkin
local setUpPieSkins
local setUpPieModel


----- Player check -----

checkPlayerAlive = function(player: Player)
	local character = player and player.Character
	local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
	if not (humanoid and humanoid.Health > 0) then
		return false
	end
	return true
end


----- Visual -----

setPieModelTransparency = function(caller: Player, transparency: number?) -- Modified from ClientToolVisual
	-- Validate
	if not (transparency == nil or tonumber(transparency)) then
		return
	end
	if not (caller == Tooling.getOwner()) then
		return
	end

	-- Change transparency
	Globals.currentTransparency = transparency
	for _, part in Tooling.pieModel:GetDescendants() do
		if part:IsA("BasePart") then
			if transparency then
				part.Transparency = transparency
			else
				local originalTransparency = part:FindFirstChild("OriginalTransparency")
				if originalTransparency and originalTransparency:IsA("NumberValue") then
					part.Transparency = originalTransparency.Value
				end
			end
		end
	end

	-- Client side
	if not checkPlayerAlive(caller) then
		return
	end

	BelovedRemote.fire_toClient("Done Setting Pie Transparency", caller, transparency)
	-- Send event twice to ensure client updates correctly
	task.delay(0.03, function()
		BelovedRemote.fire_toClient("Done Setting Pie Transparency", caller, transparency)
	end)
end

renewPieModelTransparency = function()
	-- Renew transparency
	local player = Tooling.getOwner()
	if player then
		setPieModelTransparency(player, Globals.currentTransparency)
	end
end

recordOriginalProperties = function(part: BasePart)
	-- Record original transparency
	if not part:FindFirstChild("OriginalTransparency") then
		local originalTransparency = Instance.new("NumberValue")
		originalTransparency.Name = "OriginalTransparency"
		originalTransparency.Value = part.Transparency
		originalTransparency.Parent = part
	end

	-- Record original CanCollide and CanTouch
	if not part:FindFirstChild("OriginalCanCollide") then
		local originalCanCollide = Instance.new("BoolValue")
		originalCanCollide.Name = "OriginalCanCollide"
		originalCanCollide.Value = part.CanCollide
		originalCanCollide.Parent = part
	end
	if not part:FindFirstChild("OriginalCanTouch") then
		local originalCanTouch = Instance.new("BoolValue")
		originalCanTouch.Name = "OriginalCanTouch"
		originalCanTouch.Value = part.CanTouch
		originalCanTouch.Parent = part
	end
	if not part:FindFirstChild("OriginalCanQuery") then
		local originalCanQuery = Instance.new("BoolValue")
		originalCanQuery.Name = "OriginalCanQuery"
		originalCanQuery.Value = part.CanQuery
		originalCanQuery.Parent = part
	end
end


----- Set up -----

setUpPieSkin = function(skinModel: Model)
	-- Validate pie skin
	local pieSkinMainPart = skinModel:FindFirstChild("SkinMainPart")
	if not (SkinUtil.getIsSkinModel(skinModel) and pieSkinMainPart and pieSkinMainPart:IsA("BasePart")) then
		return
	end

	-- Go through all parts in the pie skin
	for _, part in skinModel:GetDescendants() do
		if part:IsA("BasePart") then
			-- Connect parts together
			if part.AssemblyRootPart ~= pieSkinMainPart.AssemblyRootPart then
				local weldConstraint = Instance.new("WeldConstraint")
				weldConstraint.Part0 = part
				weldConstraint.Part1 = pieSkinMainPart
				weldConstraint.Parent = part
			end

			-- Record original properties
			recordOriginalProperties(part)

			-- Make invisible
			part.Transparency = 1

			-- Disable CanCollide, CanTouch, and CanQuery
			part.CanCollide = false
			part.CanTouch = false
			part.CanQuery = false
		end
	end
end

setUpPieSkins = function()
	-- Go through all pie skins
	for _, skinModel in Tooling.pieSkinsFolder:GetChildren() do
		local pieSkinMainPart = skinModel:FindFirstChild("SkinMainPart")
		if not (SkinUtil.getIsSkinModel(skinModel) and pieSkinMainPart and pieSkinMainPart:IsA("BasePart")) then
			continue
		end
		setUpPieSkin(skinModel)
	end
end

setUpPieModel = function()
	-- Go through all parts in the PieModel
	for _, part in Tooling.pieModel:GetDescendants() do
		if part:IsA("BasePart") then
			-- Connect parts together
			if part.AssemblyRootPart ~= Tooling.pieMainPart.AssemblyRootPart then
				local weldConstraint = Instance.new("WeldConstraint")
				weldConstraint.Part0 = part
				weldConstraint.Part1 = Tooling.pieMainPart
				weldConstraint.Parent = part
			end

			-- Record original properties
			recordOriginalProperties(part)

			-- Disable CanCollide, CanTouch, and CanQuery
			part.CanCollide = false
			part.CanTouch = false
			part.CanQuery = false
		end
	end
end


----- Main -----

local function main()
	Constants.apiBindableEvent.Event:Connect(function(mode: string, ...)
		if mode == "Renew Pie Transparency" then
			renewPieModelTransparency()
		end
	end)

	-- Remote events
	BelovedRemote.connect_toServer("Server Set Pie Transparency", setPieModelTransparency)

	-- Set up
	task.defer(setUpPieModel)
	task.defer(setUpPieSkins)
	Tooling.pieSkinsFolder.ChildAdded:Connect(setUpPieSkin)
end


---------- Calling function ----------

main()
