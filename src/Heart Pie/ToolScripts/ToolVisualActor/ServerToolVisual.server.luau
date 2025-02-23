--!strict
-- Server Tool Visual Script

---------- Services ----------

local Players = game:GetService("Players")

---------- Instances ----------

local Tool = script.Parent.Parent.Parent

local ToolEvents = Tool:WaitForChild("ToolEvents")
local ToolVisualEvent = ToolEvents:WaitForChild("ToolVisualEvent")
local ToolVisualRemoteEvent = ToolEvents:WaitForChild("ToolVisualRemoteEvent")

local PieModel = Tool:WaitForChild("PieModel")
local PieMainPart = PieModel:WaitForChild("MainPart")

local PieSkins = Tool:WaitForChild("PieSkins")

---------- Variables ----------

local currentTransparency: number? = nil

local character: Model? = nil
local humanoid: Humanoid? = nil
local player: Player? = nil

---------- Local functions ----------

local function checkPlayerAlive() -- Copied from "PieHandler"
	-- Check whether the variables refer to an alive player
	if not (character and character.Parent) then
		return false
	end
	if not (humanoid and humanoid.Parent and humanoid.Health > 0) then
		return false
	end
	if not (player and player.Parent) then
		return false
	end
	return true
end

local function setPieModelTransparency(caller: Player, transparency: number?) -- Modified from ClientToolVisual
	-- Validate
	if not (transparency == nil or tonumber(transparency)) then
		return
	end

	-- Change transparency
	currentTransparency = transparency
	for _, part in PieModel:GetDescendants() do
		if part:IsA("BasePart") then
			if transparency then
				part.Transparency = transparency
			else
				local originalTransparency = part:FindFirstChild("OriginalTransparency") :: NumberValue
				if originalTransparency then
					part.Transparency = originalTransparency.Value
				end
			end
		end
	end

	-- Client side
	if not checkPlayerAlive() then
		return
	end
	ToolVisualRemoteEvent:FireClient(caller, "Done Setting Pie Transparency", transparency)
	-- Send event twice to ensure client updates correctly
	task.delay(0.03, function()
		ToolVisualRemoteEvent:FireClient(caller, "Done Setting Pie Transparency", transparency)
	end)
end

local function renewPieModelTransparency()
	-- Renew transparency
	setPieModelTransparency(player, currentTransparency)
end

local function recordOriginalProperties(part: Part)
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

local function setUpPieSkin(pieSkin: Instance)
	-- Validate pie skin
	local pieSkinMainPart: Part = pieSkin:FindFirstChild("SkinMainPart")
	if not (pieSkin:IsA("Model") and pieSkinMainPart) then
		return
	end
	-- print("visual setting up " .. pieSkin.Name)

	-- Go through all parts in the pie skin
	for _, part in pieSkin:GetDescendants() do
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

local function setupPieSkins()
	-- Go through all pie skins
	for _, pieSkin in PieSkins:GetChildren() do
		local pieSkinMainPart: Part = pieSkin:FindFirstChild("SkinMainPart")
		if not (pieSkin:IsA("Model") and pieSkinMainPart) then
			continue
		end
		setUpPieSkin(pieSkin)
	end
end

local function setupPieModel()
	-- Go through all parts in the PieModel
	for _, part in PieModel:GetDescendants() do
		if part:IsA("BasePart") then
			-- Connect parts together
			if part.AssemblyRootPart ~= PieMainPart.AssemblyRootPart then
				local weldConstraint = Instance.new("WeldConstraint")
				weldConstraint.Part0 = part
				weldConstraint.Part1 = PieMainPart
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

---------- Tool functions ----------

local function onEquipped()
	character = Tool.Parent
	humanoid = character and character:FindFirstChildOfClass("Humanoid")
	player = character and Players:GetPlayerFromCharacter(character)
end

local function onUnequipped()
	character = nil
	humanoid = nil
	player = nil
end

---------- Event functions ----------

local function onToolVisualServerEvent(player: Player, mode: string, ...)
	if mode == "Set Pie Transparency" then
		setPieModelTransparency(player, ...)
	end
end

local function onToolVisualEvent(mode: string, ...)
	if mode == "Renew Pie Transparency" then
		renewPieModelTransparency()
	end
end

---------- Calling / connection functions ----------

ToolVisualEvent.Event:Connect(onToolVisualEvent)
ToolVisualRemoteEvent.OnServerEvent:Connect(onToolVisualServerEvent)
Tool.Equipped:Connect(onEquipped)
Tool.Unequipped:Connect(onUnequipped)
task.defer(setupPieModel)
task.defer(function()
	setupPieSkins()
	PieSkins.ChildAdded:Connect(setUpPieSkin)
end)
