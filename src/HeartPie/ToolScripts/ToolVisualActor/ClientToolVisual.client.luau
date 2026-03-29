--!strict
-- Client Tool Visual Script


---------- Services ----------

local Players = game:GetService("Players")


---------- Instances ----------

local Tool = script.Parent.Parent.Parent

local ToolEvents = Tool:WaitForChild("ToolEvents")
local ToolVisualEvent = ToolEvents:WaitForChild("ToolVisualEvent")
local ToolVisualRemoteEvent = ToolEvents:WaitForChild("ToolVisualRemoteEvent")

local PieModel = Tool:WaitForChild("PieModel")


---------- Variables ----------

local currentTransparency: number? = nil

local character: Model? = nil
local humanoid: Humanoid? = nil
local player: Player? = nil


---------- Local functions ----------

local function setPieModelTransparency(transparency: number?)
	-- Validate
	if not (transparency == nil or tonumber(transparency)) then
		return
	end

	-- Change transparency
	currentTransparency = transparency
	ToolVisualRemoteEvent:FireServer("Set Pie Transparency", transparency)
	for _, part in PieModel:GetDescendants() do
		if part:IsA("BasePart") then
			local originalTransparency = part:FindFirstChild("OriginalTransparency") :: NumberValue
			if transparency then
				part.Transparency = transparency
			elseif originalTransparency then
				part.Transparency = originalTransparency.Value
			end
		end
	end
end

local function onServerDoneSettingPieTransparency(transparency: number?)
	-- Set transparency back to current value for the Client
	for _, part in PieModel:GetDescendants() do
		if part:IsA("BasePart") then
			-- Client's transparency
			local originalTransparency = part:FindFirstChild("OriginalTransparency") :: NumberValue
			local clientTransparency: number? = nil
			if tonumber(currentTransparency) then
				clientTransparency = currentTransparency
			elseif originalTransparency then
				clientTransparency = originalTransparency.Value
			end
			-- Server's transparency
			local serverTransparency: number? = nil
			if tonumber(transparency) then
				serverTransparency = transparency
			elseif originalTransparency then
				serverTransparency = originalTransparency.Value
			end

			-- Change transparency if different
			if clientTransparency and clientTransparency ~= serverTransparency then
				part.Transparency = clientTransparency
			end
		end
	end
end

local function onToolEquipped()
	character = Tool.Parent
	humanoid = character and character:FindFirstChildOfClass("Humanoid")
	player = character and Players:GetPlayerFromCharacter(character)
end

local function onToolUnequipped()
	character = nil
	humanoid = nil
	player = nil
end


---------- Event functions ----------

local function onToolVisualEvent(mode: string, ...)
	if mode == "Set Pie Transparency" then
		setPieModelTransparency(...)
	end
end

local function onToolVisualClientEvent(mode: string, ...)
	if mode == "Done Setting Pie Transparency" then
		onServerDoneSettingPieTransparency(...)
	end
end


---------- Calling / connecting functions ----------

ToolVisualEvent.Event:Connect(onToolVisualEvent)
ToolVisualRemoteEvent.OnClientEvent:Connect(onToolVisualClientEvent)
Tool.Equipped:Connect(onToolEquipped)
Tool.Unequipped:Connect(onToolUnequipped)
task.defer(function()
	while not (PieModel:FindFirstChild("PieSkin") and player) do
		task.wait(0.03)
	end
	setPieModelTransparency(nil)
end)
