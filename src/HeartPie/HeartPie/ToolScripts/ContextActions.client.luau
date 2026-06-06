--!strict

-- Context Actions


---------- Services ----------

local ContextActionService = game:GetService("ContextActionService")


---------- Imports ----------

local _ToolScripts = script.Parent
local _PieSkins = _ToolScripts:WaitForChild("PieSkins")
local ClientPieSkinApi = require(_PieSkins:WaitForChild("ClientPieSkinApi"))

local _ToolUse = _ToolScripts:WaitForChild("ToolUse")
local ClientToolUseApi = require(_ToolUse:WaitForChild("ClientToolUseApi"))

local ToolGuiApi = require(_ToolScripts:WaitForChild("ToolGuiApi"))


---------- Constants ----------

local Constants = {}

Constants.tool = script.Parent.Parent

table.freeze(Constants)


---------- Local functions ----------

local handleAction

local onActivated
local onEquipped
local onUnequipped


----- Actions -----

handleAction = function(actionName: string, inputState: Enum.UserInputState, inputObject: InputObject)
	local isBeginState = (inputState == Enum.UserInputState.Begin)
	local isCancelOrEndState = (inputState == Enum.UserInputState.Cancel) or (inputState == Enum.UserInputState.End)

	if actionName == "Pie Next Skin" then
		if isBeginState then
			ClientPieSkinApi.changeSkinIdBy(1)
		end
	elseif actionName == "Pie Previous Skin" then
		if isBeginState then
			ClientPieSkinApi.changeSkinIdBy(-1)
		end
	elseif actionName == "Pie Switch Type" then
		if isBeginState then
			ToolGuiApi.switchPieType()
		end
	end
end


----- Events -----

onActivated = function()
	ClientToolUseApi.launchPie()
end

onEquipped = function()
	ContextActionService:BindAction("Pie Next Skin", handleAction, true, Enum.KeyCode.E)
	ContextActionService:BindAction("Pie Previous Skin", handleAction, true, Enum.KeyCode.Q)
	ContextActionService:BindAction("Pie Switch Type", handleAction, false, Enum.KeyCode.T)

	ContextActionService:SetTitle("Pie Previous Skin", "Prev")
	ContextActionService:SetTitle("Pie Next Skin", "Next")
	ContextActionService:SetPosition("Pie Previous Skin", UDim2.new(0, 0, 0, 0))
	ContextActionService:SetPosition("Pie Next Skin", UDim2.new(0, 50, 0, 0))
end

onUnequipped = function()
	ContextActionService:UnbindAction("Pie Next Skin")
	ContextActionService:UnbindAction("Pie Previous Skin")
	ContextActionService:UnbindAction("Pie Switch Type")
end


----- Main -----

local function main()
	Constants.tool.Activated:Connect(onActivated)
	Constants.tool.Equipped:Connect(onEquipped)
	Constants.tool.Unequipped:Connect(onUnequipped)
end


---------- Calling function ----------

main()
