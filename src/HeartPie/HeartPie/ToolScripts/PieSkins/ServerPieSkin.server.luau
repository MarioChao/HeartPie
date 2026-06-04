--!strict
-- Server Pie Skins Script


---------- Validate container ----------

-- Under data model
if not script:FindFirstAncestorWhichIsA("DataModel") then
	return
end


---------- Services ----------

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")


---------- Imports ----------

local _PieHiking_ServerScripts = ServerScriptService:WaitForChild("PieHiking_ServerScripts")
local _SkinModules = _PieHiking_ServerScripts:WaitForChild("SkinModules")
local PieSkinsApi = require(_SkinModules:WaitForChild("PieSkinsApi"))
local SkinUtil = require(_SkinModules:WaitForChild("SkinUtil"))


---------- Types ----------

type SkinInfo = {Id: number, Model: Model}


---------- Instances ----------

local Tool = script.Parent.Parent.Parent
local ToolEvents = Tool:WaitForChild("ToolEvents")
local PieSkinRemoteEvent = ToolEvents:WaitForChild("PieSkinRemoteEvent")
local ToolVisualEvent = ToolEvents:WaitForChild("ToolVisualEvent")

local PieModel = Tool:WaitForChild("PieModel")
local PieMainPart = PieModel:WaitForChild("MainPart")
local PieMainPartAttachment = PieMainPart:WaitForChild("PieAttachment")

local PieSkins = Tool:WaitForChild("PieSkins")


---------- Variables ----------

local pieSkinsTable: {SkinInfo}

local character: Model? = nil
local player: Player? = nil

local changeSkinIdThrottle = false

local skinAddedDebounceId = -1


---------- Skin id functions ----------

local function setSkinIdTo(newSkinId: number, dontSave: boolean?)
	-- Validate skin
	newSkinId = (newSkinId - 1) % (#pieSkinsTable) + 1
	if not pieSkinsTable[newSkinId] then
		return
	end

	-- Remove old skin
	local oldPieSkinFolder = PieModel:FindFirstChild("PieSkin")
	if oldPieSkinFolder then
		oldPieSkinFolder:Destroy()
	end

	-- Update new skin
	PieModel:SetAttribute("EquippedSkinId", newSkinId)
	local newPieSkinFolder = Instance.new("Folder")
	newPieSkinFolder.Name = "PieSkin"
	local newPieSkinInfo = pieSkinsTable[newSkinId]
	local newPieSkinModel = newPieSkinInfo.Model:Clone()
	newPieSkinModel.Parent = newPieSkinFolder

	newPieSkinFolder.Parent = PieModel -- Might cause exception

	-- Update tool properties
	local skinConfig = SkinUtil.getSkinConfig(newPieSkinModel)
	if skinConfig then
		Tool.TextureId = skinConfig.toolTextureId
		Tool.ToolTip = skinConfig.toolTip
	end

	-- Renew transparency
	ToolVisualEvent:Fire("Renew Pie Transparency")

	-- Save skin
	if not dontSave then
		local userId = player and player.UserId
		if userId then
			PieSkinsApi.saveUserSkinId(userId, newPieSkinInfo.Id)
		end
	end
end

local function setRealSkinIdTo(realSkinId: number, dontSave: boolean?)
	local newSkinId = 1
	for id, pieSkinInfo in pieSkinsTable do
		if pieSkinInfo.Id == realSkinId then
			newSkinId = id
			break
		end
	end
	setSkinIdTo(newSkinId, dontSave)
end

local function changeSkinIdBy(caller: Player, amount: number)
	if not changeSkinIdThrottle then
		changeSkinIdThrottle = true

		-- Validate
		if not (caller == player and tonumber(amount)) then
			return
		end

		-- Get new skin id of the pie model
		local oldSkinId = PieModel:GetAttribute("EquippedSkinId")
		-- About positive modulo: https://devforum.roblox.com/t/how-to-get-value-which-will-follow-formula-y-x-1-16-1-but-also-for-negative-numbers/2322681
		local newSkinId = (oldSkinId + amount - 1) % (#pieSkinsTable) + 1
		if not pieSkinsTable[newSkinId] then
			return
		end

		-- Remove old skin
		setSkinIdTo(newSkinId)

		changeSkinIdThrottle = false
	end
end

---------- Skin setup functions ----------

local function setUpPieSkin(skin: Model)
    -- Validate skin main part
    local skinMainPart = skin:FindFirstChild("SkinMainPart")
    if not (skinMainPart and skinMainPart:IsA("BasePart")) then
        return
    end

    -- Get attachment
    local skinAttachment = skinMainPart:FindFirstChild("PieSkinAttachment")
	if not (skinAttachment and skinAttachment:IsA("Attachment")) then
		warn(`[Server Pie Skin]: No skin attachment found for skin {skin}.`)
		return
	end

	-- Set up rigid constraint
	local rigidConstraint = skinMainPart:FindFirstChild("RigidConstraint")
	if rigidConstraint and rigidConstraint:IsA("RigidConstraint") then
		rigidConstraint.Attachment0 = skinAttachment
		rigidConstraint.Attachment1 = PieMainPartAttachment
	else
		warn(`[Server Pie Skin]: No rigid constraint found for skin {skin}.`)
	end

	-- Set up mass
	for _, part in skin:GetDescendants() do
		if part:IsA("BasePart") then
			part.Massless = true
		end
	end
end

local function setUpPieSkinsTable()
	changeSkinIdThrottle = true

	-- Set reference properties
	for _, skinModel in PieSkins:GetChildren() do
		if SkinUtil.getIsSkinModel(skinModel) then
			setUpPieSkin(skinModel)
		end
	end

	-- Record valid pie skins from folder
	local validPieSkinsInfo = {} :: {SkinInfo}
	for _, skinModel in PieSkins:GetChildren() do
		-- Validate pie skin
		local skinConfig = SkinUtil.getSkinConfig(skinModel)
		if not (SkinUtil.getIsSkinModel(skinModel) and skinConfig) then
			continue
		end

		-- Check do not load
		if skinConfig.doNotLoad then
			continue
		end

		-- Add to valid pie skins
		local skinInfo = {["Id"] = skinConfig.skinId, ["Model"] = skinModel}
		table.insert(validPieSkinsInfo, skinInfo)
	end

	-- Sort valid pie skins by id
	table.sort(validPieSkinsInfo, function (a, b)
		return a.Id < b.Id
	end)

	-- Store pie skins in table
	pieSkinsTable = {} :: {SkinInfo}
	for _, pieSkinInfo in validPieSkinsInfo do
		table.insert(pieSkinsTable, pieSkinInfo)
	end

	changeSkinIdThrottle = false
end

local function onNewSkinsAdded(skin: Instance)
	-- Debounce
	-- If many skins are added in a short period,
	-- wait until the last one is added, then proceed with the following code
	local debounceId = HttpService:GenerateGUID()
	skinAddedDebounceId = debounceId
	task.wait(0.3)

	-- Check if debounce changed
	if skinAddedDebounceId ~= debounceId then
		return
	end
	-- print("Running skin added, " .. skin.Name)

	-- Store equipped skin id
	local oldSkinId = PieModel:GetAttribute("EquippedSkinId")
	local realSkinId = pieSkinsTable[oldSkinId] and pieSkinsTable[oldSkinId].Id or 0

	-- Used saved skin id if possible
	local userId = player and player.UserId
	if userId then
		local savedRealSkinId = PieSkinsApi.getUserSkinId(userId)
		if savedRealSkinId then
			realSkinId = savedRealSkinId
		end
	end

	-- Refresh pie skins table
	setUpPieSkinsTable()

	-- Equip the original pie skin
	setRealSkinIdTo(realSkinId, true)
end

local function loadSavedSkin()
	-- Check variable
	local tempPlayer = player

	-- Check character
	if not tempPlayer then
		local tempCharacter = Tool.Parent
		tempPlayer = tempCharacter and Players:GetPlayerFromCharacter(tempCharacter)
	end

	-- Check player is ancestor
	if not tempPlayer then
		tempPlayer = Tool:FindFirstAncestorWhichIsA("Player")
	end

	-- Populate skins
	if tempPlayer then
		PieSkinsApi.populateToolSkins(Tool)
	end

	-- Switch skin
	local userId = tempPlayer and tempPlayer.UserId
	if userId then
		local savedRealSkinId = PieSkinsApi.getUserSkinId(userId)
		if savedRealSkinId then
			setRealSkinIdTo(savedRealSkinId, true)
		end
	end
end

local function onToolEquipped()
	character = Tool.Parent
	player = character and Players:GetPlayerFromCharacter(character)
	loadSavedSkin()
end

local function onToolUnequipped()
	character = nil
	player = nil
end

local function initSetUp()
	setUpPieSkinsTable()
	setSkinIdTo(PieModel:GetAttribute("EquippedSkinId"), true)

	-- Events for changing skins
	PieSkins.ChildAdded:Connect(onNewSkinsAdded)
	PieSkins.ChildRemoved:Connect(onNewSkinsAdded)
end


---------- Event functions ----------

local function onPieSkinServerEvent(caller: Player, mode: string, ...)
	if mode == "Change Skin Id By" then
		changeSkinIdBy(caller, ...)
	end
end


---------- Calling / connecting functions ----------

Tool.Equipped:Connect(onToolEquipped)
Tool.Unequipped:Connect(onToolUnequipped)
PieSkinRemoteEvent.OnServerEvent:Connect(onPieSkinServerEvent)
initSetUp()
