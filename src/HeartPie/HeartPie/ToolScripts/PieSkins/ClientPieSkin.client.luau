--!strict
-- Client Pie Skins Script


---------- Validate container ----------

-- Under data model
if not script:FindFirstAncestorWhichIsA("DataModel") then
	return
end


---------- Instances ----------

local Tool = script.Parent.Parent.Parent

local ToolEvents = Tool:WaitForChild("ToolEvents")
local ActionsBindable = ToolEvents:WaitForChild("ActionsBindable")

local PieSkinRemoteEvent = ToolEvents:WaitForChild("PieSkinRemoteEvent")


---------- Local functions ----------

local function changeSkinIdBy(amount: number)
	PieSkinRemoteEvent:FireServer("Change Skin Id By", amount)
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
