--!strict

-- Mouse Icon


---------- Services ----------

local UserInputService = game:GetService("UserInputService")


---------- Imports ----------

local _ToolScripts = script.Parent
local Tooling = require(_ToolScripts:WaitForChild("Tooling"))


---------- Globals ----------

local Globals = {}

Globals.toolMouse = nil :: Mouse?


---------- Local functions ----------

local setCursor
local changeCursor

local onEquipped
local onUnequipped
local onIconChanged


----- Cursor -----

setCursor = function(icon: string)
	-- Validate equipped
	if icon ~= "" and not Tooling.getIsEquipped() then
		return
	end

	-- Set icon
	UserInputService.MouseIcon = icon
	if Globals.toolMouse then
		Globals.toolMouse.Icon = icon
	end
end

changeCursor = function()
	local iconValue = Tooling.values.getMouseIconValue()
	if iconValue == 0 then
		-- Loaded
		setCursor("rbxasset://textures/GunCursor.png")
	elseif iconValue == 1 then
		-- Reloading (baking)
		setCursor("rbxassetid://6061556793")
	elseif iconValue == 2 then
		-- Throw
		setCursor("rbxassetid://5992316447")
	else
		setCursor("")
	end
end


----- Events -----

onEquipped = function(currentMouse: Mouse)
	if not currentMouse then
		return
	end
	Globals.toolMouse = currentMouse
	changeCursor()
end

onUnequipped = function()
	Globals.toolMouse = nil
	setCursor("")
end

onIconChanged = function()
	changeCursor()
end


----- Main -----

local function main()
	Tooling.tool.Equipped:Connect(onEquipped)
	Tooling.tool.Unequipped:Connect(onUnequipped)
	Tooling.toolStates:GetAttributeChangedSignal("MouseIconValue"):Connect(onIconChanged)
end


---------- Calling function ----------

main()
