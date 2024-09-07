--!strict
-- Client Pie Skins Script

---------- Instances ----------

local Tool = script.Parent.Parent.Parent

local ToolEvents = Tool:WaitForChild("ToolEvents")
local ActionsBindable = ToolEvents:WaitForChild("ActionsBindable")

local PieSkinRemoteEvent = ToolEvents:WaitForChild("PieSkinRemoteEvent")

---------- Variables ----------

local changeSkinIdThrottle = false

---------- Local functions ----------

local function changeSkinIdBy(amount: number)
	if not changeSkinIdThrottle then
		changeSkinIdThrottle = true
		task.delay(0.1, function()
			changeSkinIdThrottle = false
		end)

		PieSkinRemoteEvent:FireServer("Change Skin Id By", amount)
	end
end

---------- Event functions ----------

local function onActionsEvent(mode: string, ...)
	-- Validate equipped
	if not Tool.Equipped then
		return
	end

	-- Actions
	if mode == "Next Skin" then
		changeSkinIdBy(1)
	elseif mode == "Previous Skin" then
		changeSkinIdBy(-1)
	end
end

---------- Calling / connecting functions ----------

ActionsBindable.Event:Connect(onActionsEvent)
