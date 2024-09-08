--!strict
-- Context Actions Script

---------- Validate container ----------

if not (script:FindFirstAncestorWhichIsA("Workspace") or script:FindFirstAncestorWhichIsA("Backpack")) then
	return
end

---------- Services ----------

local ContextActionService = game:GetService("ContextActionService")

---------- Instances ----------

local Tool = script.Parent.Parent.Parent
local ToolEvents = Tool:WaitForChild("ToolEvents")
local ActionsBindable = ToolEvents:WaitForChild("ActionsBindable")

---------- Local functions ----------

local function handleAction(actionName: string, inputState: Enum.UserInputState, inputObject: InputObject)
	local isBeginState = (inputState == Enum.UserInputState.Begin)
	local isCancelOrEndState = (inputState == Enum.UserInputState.Cancel) or (inputState == Enum.UserInputState.End)

	if actionName == "Pie Next Skin" then
		if isBeginState then
			ActionsBindable:Fire("Next Skin")
		end
	elseif actionName == "Pie Previous Skin" then
		if isBeginState then
			ActionsBindable:Fire("Previous Skin")
		end
	elseif actionName == "Pie Switch Type" then
		if isBeginState then
			ActionsBindable:Fire("Switch Pie Type")
		end
	end
end

---------- Event functions ----------

local function onActivated()
	ActionsBindable:Fire("Pie Launch")
end

local function onEquipped()
	ContextActionService:BindAction("Pie Next Skin", handleAction, true, Enum.KeyCode.E)
	ContextActionService:BindAction("Pie Previous Skin", handleAction, true, Enum.KeyCode.Q)
	ContextActionService:BindAction("Pie Switch Type", handleAction, false, Enum.KeyCode.T)
end

local function onUnequipped()
	ContextActionService:UnbindAction("Pie Next Skin")
	ContextActionService:UnbindAction("Pie Previous Skin")
	ContextActionService:UnbindAction("Pie Switch Type")
end

---------- Calling / connecting functions ----------

Tool.Equipped:Connect(onEquipped)
Tool.Unequipped:Connect(onUnequipped)
Tool.Activated:Connect(onActivated)
