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
local StarterPieSkinsGetter = require(_SkinModules:WaitForChild("StarterPieSkinsGetter"))
local ConditionalPieSkinsGetter = require(_SkinModules:WaitForChild("ConditionalPieSkinsGetter"))


---------- Constants ----------

local Constants = {}

do
	local _ApiBindables = script.Parent:WaitForChild("ApiBindables")
	Constants.apiBindableEvent = _ApiBindables:WaitForChild("ApiBindableEvent")
	Constants.apiBindableFunction = _ApiBindables:WaitForChild("ApiBindableFunction")
end

Constants.pieSkinsFolderName = "CurrentPieSkins"

table.freeze(Constants)


---------- Globals ----------

local Globals = {}

Globals.userId_savedSkinId = {} :: {[number]: number}


---------- Local functions ----------

local saveUserSkinId
local getUserSkinId

local populateUniqueSkins
local populateToolSkins
local getStarterPieSkins
local getPlayerConditionalPieSkins


----- Saved skins -----

saveUserSkinId = function(userId: number, skinId: number)
	Globals.userId_savedSkinId[userId] = skinId
end

getUserSkinId = function(userId: number)
	return Globals.userId_savedSkinId[userId]
end


----- Pie skins -----

populateUniqueSkins = function(pieSkinsFolder: Folder, skinsToAdd: {Model})
	-- Check existing skins
	local isSkinAdded = {} :: {[string]: boolean}
	for _, pieSkin: Instance in pieSkinsFolder:GetChildren() do
		isSkinAdded[pieSkin.Name] = true
	end

	-- Get new pie skins
	local notAddedSkins = {} :: {Model}
	for _, pieSkin in skinsToAdd do
		if isSkinAdded[pieSkin.Name] then
			continue
		end
		table.insert(notAddedSkins, pieSkin)
		isSkinAdded[pieSkin.Name] = true
	end

	-- Clone new pie skins to the folder
	for _, pieSkin in notAddedSkins do
		local newPieSkin = pieSkin:Clone()
		newPieSkin.Parent = pieSkinsFolder
	end
end

-- Add new skins to the pie tool, if the holder has them unlocked
populateToolSkins = function(pieTool: Tool)
	-- Get the skins folder
	local toolPieSkinsFolder = (function()
		local child = pieTool:FindFirstChild(Constants.pieSkinsFolderName)
		local result
		if child and child:IsA("Folder") then
			result = child
		else
			result = Instance.new("Folder")
			result.Name = Constants.pieSkinsFolderName
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

	-- Populate default pie skins
	local starterPieSkins = getStarterPieSkins()
	populateUniqueSkins(toolPieSkinsFolder, starterPieSkins)

	-- Populate conditional pie skins
	local conditionalPieSkins = getPlayerConditionalPieSkins(player)
	populateUniqueSkins(toolPieSkinsFolder, conditionalPieSkins)
end

getStarterPieSkins = function()
	local result = {}

	-- Go through starter pie skins
	for skinName, pieSkinModel in StarterPieSkinsGetter.getTable() do
		-- Add to result
		table.insert(result, pieSkinModel)
	end

	return result
end

getPlayerConditionalPieSkins = function(player: Player)
	local userId = player.UserId
	local result = {}

	-- Go through conditional pie skins
	for skinName, pieSkinModel in ConditionalPieSkinsGetter.getTable() do
		-- Check condition
		local condition = PieSkinConditionsGetter.getValueAt(skinName)
		if not (condition and condition(userId)) then
			continue
		end

		-- Add to result
		table.insert(result, pieSkinModel)
	end

	-- Return result
	return result
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
