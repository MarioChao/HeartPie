--!strict

-- Pie Skins System


---------- Validate container ----------

-- Server script service
if not script:FindFirstAncestorWhichIsA("ServerScriptService") then
	return
end


---------- Services ----------

local Players = game:GetService("Players")


---------- Imports ----------

local _SkinModules = script.Parent.Parent
local PieSkinConditionsGetter = require(_SkinModules:WaitForChild("PieSkinConditionsGetter"))
local PieSkinsGetter = require(_SkinModules:WaitForChild("PieSkinsGetter"))


---------- Constants ----------

local Constants = {}

do
	local _ApiBindables = script.Parent:WaitForChild("ApiBindables")
	Constants.apiBindableEvent = _ApiBindables:WaitForChild("ApiBindableEvent")
	Constants.apiBindableFunction = _ApiBindables:WaitForChild("ApiBindableFunction")
end

table.freeze(Constants)


---------- Globals ----------

local Globals = {}

Globals.userId_savedSkinId = {} :: {[number]: number}


---------- Local functions ----------

local saveUserSkinId
local getUserSkinId

local populateToolSkins
local getPlayerConditionalPieSkins


----- Saved skins -----

saveUserSkinId = function(userId: number, skinId: number)
	Globals.userId_savedSkinId[userId] = skinId
end

getUserSkinId = function(userId: number)
	return Globals.userId_savedSkinId[userId]
end


----- Pie skins -----

-- Add new skins to the pie tool, if the holder has them unlocked
populateToolSkins = function(pieTool: Tool)
	-- Get the skins folder
	local toolPieSkinsFolder = (function()
		local child = pieTool:FindFirstChild("PieSkins")
		local result
		if child then
			result = child
		else
			result = Instance.new("Folder")
			result.Name = "PieSkins"
		end
		return result
	end)()

	-- Get player
	local player = (function(): Player?
		-- Check character
		local character = pieTool.Parent
		local characterPlayer = character and Players:GetPlayerFromCharacter(character)
		local result
		if characterPlayer then
			result = characterPlayer
		else
			-- Check player in ancestor (if tool under backpack)
			result = pieTool:FindFirstAncestorWhichIsA("Player")
		end
		return result
	end)()

	-- Validate player
	if not player then
		return
	end

	-- Get player's pie skins
	local conditionalPieSkins = getPlayerConditionalPieSkins(player)

	-- Go through tool's existing skins
	local isSkinAdded: {[string]: boolean} = {}
	for _, pieSkin: Instance in toolPieSkinsFolder:GetChildren() do
		isSkinAdded[pieSkin.Name] = true
	end

	-- Go through conditional pie skins
	local notAddedSkins: {Instance} = {}
	for _, pieSkin: Instance in conditionalPieSkins do
		if isSkinAdded[pieSkin.Name] then
			continue
		end
		table.insert(notAddedSkins, pieSkin)
		isSkinAdded[pieSkin.Name] = true
	end

	-- Clone new pie skins to the tool
	for _, pieSkin in notAddedSkins do
		local newPieSkin = pieSkin:Clone()
		newPieSkin.Parent = toolPieSkinsFolder
	end
end

getPlayerConditionalPieSkins = function(player: Player)
	local userId = player.UserId
	local conditionalPieSkins: {Instance} = {}

	-- Go through instances in the folder
	for skinName, pieSkinModel in PieSkinsGetter.getTable() do
		-- Check condition
		local condition = PieSkinConditionsGetter.getValueAt(skinName)
		if not (condition and condition(userId)) then
			continue
		end

		-- Add to result
		table.insert(conditionalPieSkins, pieSkinModel)
	end

	-- Return result
	return conditionalPieSkins
end


----- Main -----

local function main()
	-- Bindable event
	Constants.apiBindableEvent.Event:Connect(function(mode: string, ...)
		if mode == "Save User Skin Id" then
			saveUserSkinId(...)
		elseif mode == "Populate Tool Skins" then
			populateToolSkins(...)
		end
	end)

	-- Bindable function
	Constants.apiBindableFunction.OnInvoke = function(mode: string, ...): any
		if mode == "Get User Skin Id" then
			return getUserSkinId(...)
		end
		return
	end

	-- Clean up
	Players.PlayerRemoving:Connect(function(player: Player)
		Globals.userId_savedSkinId[player.UserId] = nil
	end)
end


---------- Calling function ----------

main()
