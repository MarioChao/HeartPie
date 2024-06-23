--!strict
-- Mouse Icon Script

-- Tool info
local Tool = script.Parent.Parent.Parent
local ToolValues = Tool:WaitForChild("ToolValues")
local Icon = ToolValues:WaitForChild("Icon")

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

-- Functions
local function setCursor(icon: string)
	if icon ~= "" and Players:GetPlayerFromCharacter(Tool.Parent) ~= Players.LocalPlayer then
		return
	end
	UserInputService.MouseIcon = icon
end

local function changeCursor()
	if Icon.Value == 0 then
		setCursor("rbxasset://textures/GunCursor.png")
	elseif Icon.Value == 1 then -- Baking
		setCursor("http://www.roblox.com/asset/?id=6061556793")
	elseif Icon.Value == 2 then -- Throw
		setCursor("http://www.roblox.com/asset/?id=5992316447")
	else
		setCursor("")
	end
end

local function onEquipped(toolmouse: Mouse)
	if toolmouse == nil then
		return
	end
	changeCursor()
end

local function onUnequipped()
	setCursor("")
end

local function onChanged(Value)
	changeCursor()
end

-- Calling / connecting functions
Tool.Equipped:Connect(onEquipped)
Tool.Unequipped:Connect(onUnequipped)
Icon.Changed:Connect(onChanged)
