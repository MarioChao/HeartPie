--!strict

-- Tooling


---------- Services ----------

local Players = game:GetService("Players")


---------- Module ----------

local Module = {}


----- Module fields -----

Module.tool = script.Parent.Parent
Module.pieModel = Module.tool:WaitForChild("PieModel")
Module.pieMainPart = Module.pieModel:WaitForChild("MainPart")
Module.pieMainPartAttachment = Module.pieMainPart:WaitForChild("PieAttachment")
Module.pieRightGripAttachment = Module.pieMainPart:WaitForChild("PieRightGripAttachment")

Module.pieSkinsFolder = Module.tool:WaitForChild("CurrentPieSkins")

Module.handle = Module.tool:WaitForChild("Handle")
Module.handleRightGripAttachment = Module.handle:WaitForChild("RightGripAttachment")


----- Module values -----

do
	local _ToolValues = Module.tool:WaitForChild("ToolValues")
	local _ToolConfig = _ToolValues:WaitForChild("ToolConfig")
	local _ToolStates = _ToolValues:WaitForChild("ToolStates")
	Module.toolConfig = _ToolConfig
	Module.toolStates = _ToolStates
	Module.configs = {
		getAutoReload = function() return _ToolConfig:GetAttribute("AutoReload") == true end,
		getCanCollideThrower = function() return _ToolConfig:GetAttribute("CanCollideThrower") == true end,
		getCanOverlapPart = function() return _ToolConfig:GetAttribute("CanOverlapPart") == true end,
		getCanSwitchType = function() return _ToolConfig:GetAttribute("CanSwitchType") == true end,
		getDurationReload = function() return tonumber(_ToolConfig:GetAttribute("DurationReload")) or 0 end,
		getDurationThrow = function() return tonumber(_ToolConfig:GetAttribute("DurationThrow")) or 0 end,
		getIsClientPieType = function() return _ToolConfig:GetAttribute("IsClientPieType") == true end,
		getLaunchOffsetStuds = function() return tonumber(_ToolConfig:GetAttribute("LaunchOffsetStuds")) or 0 end,
		getLaunchVelocity = function() return tonumber(_ToolConfig:GetAttribute("LaunchVelocity")) or 0 end,
		getNoCollideTransparency = function() return tonumber(_ToolConfig:GetAttribute("NoCollideTransparency")) or 0 end,
		getPieAlignSpin = function() return _ToolConfig:GetAttribute("PieAlignSpin") == true end,
		getPieSpinByVelocity = function() return _ToolConfig:GetAttribute("PieSpinByVelocity") == true end,
		getReloadShowPie = function() return _ToolConfig:GetAttribute("ReloadShowPie") == true end,
		getShowGui = function() return _ToolConfig:GetAttribute("ShowGui") == true end,
	}
	Module.values = {
		getMouseIconValue = function() return tonumber(_ToolStates:GetAttribute("MouseIconValue")) or 0 end,
		setMouseIconValue = function(value: number) _ToolStates:SetAttribute("MouseIconValue", value) end,
	}
end


----- Module methods -----

function Module.getOwner()
    -- Get player
	local player = (function(): Player?
		-- Check character
		local character = Module.tool.Parent
		local characterPlayer = character and Players:GetPlayerFromCharacter(character)
		local result
		if characterPlayer then
			result = characterPlayer
		else
			-- Check player in ancestor (if tool under backpack)
			result = Module.tool:FindFirstAncestorWhichIsA("Player")
		end
		return result
	end)()

    -- Return
    return player
end

function Module.getIsEquipped()
	return Players:GetPlayerFromCharacter(Module.tool.Parent) == Module.getOwner()
end


---------- Return module ----------

table.freeze(Module)
return Module
