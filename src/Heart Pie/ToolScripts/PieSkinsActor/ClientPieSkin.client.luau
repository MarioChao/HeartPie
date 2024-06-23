--!strict
-- Client Pie Skins Script

-- Tool info
local Tool = script.Parent.Parent.Parent
local ToolEvents = Tool:WaitForChild("ToolEvents")
local PieSkinRemoteEvent = ToolEvents:WaitForChild("PieSkinRemoteEvent")

-- Services
local UserInputService = game:GetService("UserInputService")

-- Variables
local changeSkinIdDebounce = false

-- Functions
local function changeSkinIdBy(amount: number)
	if not changeSkinIdDebounce then
		changeSkinIdDebounce = true
		
		task.delay(0.1, function()
			changeSkinIdDebounce = false
		end)
		
		PieSkinRemoteEvent:FireServer("Change Skin Id By", amount)
	end
end

local function onInputBegan(input: InputObject, gameProcessed: boolean)
	if not gameProcessed then
		if input.KeyCode == Enum.KeyCode.E then
			changeSkinIdBy(1)
		elseif input.KeyCode == Enum.KeyCode.Q then
			changeSkinIdBy(-1)
		end
	end
end

-- Calling / connecting functions
UserInputService.InputBegan:Connect(onInputBegan)
