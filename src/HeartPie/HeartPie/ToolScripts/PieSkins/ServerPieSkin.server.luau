--!strict

-- Server Pie Skins


---------- Services ----------

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")


---------- Imports ----------

local _PieHiking_ServerScripts = ServerScriptService:WaitForChild("PieHiking_ServerScripts")
local _SkinModules = _PieHiking_ServerScripts:WaitForChild("SkinModules")
local PieSkinsApi = require(_SkinModules:WaitForChild("PieSkinsApi"))
local SkinUtil = require(_SkinModules:WaitForChild("SkinUtil"))

local _PieHiking_SharedStorage = ReplicatedStorage:WaitForChild("PieHiking_SharedStorage")
local _Modules = _PieHiking_SharedStorage:WaitForChild("Modules")
local BelovedRemote = require(_Modules:WaitForChild("BelovedRemote"))

local _ToolScripts = script.Parent.Parent
local Tooling = require(_ToolScripts:WaitForChild("Tooling"))

local _ToolVisual = _ToolScripts:WaitForChild("ToolVisual")
local ServerToolVisualApi = require(_ToolVisual:WaitForChild("ServerToolVisualApi"))


---------- Types ----------

type SkinInfo = {Id: number, Model: Model}


---------- Globals ----------

local Globals = {}

Globals.pieSkinsTable = {} :: {SkinInfo}

Globals.changeSkinIdThrottle = false
Globals.skinAddedDebounceId = -1


---------- Local functions ----------

local setSkinIdTo
local setRealSkinIdTo
local changeSkinIdBy

local setUpPieSkin
local setUpPieSkinsTable
local onNewSkinsAdded
local loadSavedSkin
local initSetUp


----- Skin id -----

setSkinIdTo = function(newSkinId: number, dontSave: boolean?)
	-- Validate skin
	newSkinId = (newSkinId - 1) % (#Globals.pieSkinsTable) + 1
	if not Globals.pieSkinsTable[newSkinId] then
		return
	end

	-- Remove old skin
	local oldPieSkinFolder = Tooling.pieModel:FindFirstChild("PieSkin")
	if oldPieSkinFolder then
		oldPieSkinFolder:Destroy()
	end

	-- Update new skin
	Tooling.pieModel:SetAttribute("EquippedSkinId", newSkinId)
	local newPieSkinFolder = Instance.new("Folder")
	newPieSkinFolder.Name = "PieSkin"
	local newPieSkinInfo = Globals.pieSkinsTable[newSkinId]
	local newPieSkinModel = newPieSkinInfo.Model:Clone()
	newPieSkinModel.Parent = newPieSkinFolder

	newPieSkinFolder.Parent = Tooling.pieModel -- Might cause exception

	-- Update tool properties
	local skinConfig = SkinUtil.getSkinConfig(newPieSkinModel)
	if skinConfig then
		Tooling.tool.TextureId = skinConfig.toolTextureId
		Tooling.tool.ToolTip = skinConfig.toolTip
	end

	-- Renew transparency
	ServerToolVisualApi.renewPieTransparency()

	-- Save skin
	if not dontSave then
		local player = Tooling.getOwner()
		local userId = player and player.UserId
		if userId then
			PieSkinsApi.saveUserSkinId(userId, newPieSkinInfo.Id)
		end
	end
end

setRealSkinIdTo = function(realSkinId: number, dontSave: boolean?)
	local newSkinId = 1
	for id, pieSkinInfo in Globals.pieSkinsTable do
		if pieSkinInfo.Id == realSkinId then
			newSkinId = id
			break
		end
	end
	setSkinIdTo(newSkinId, dontSave)
end

changeSkinIdBy = function(caller: Player, amount: number)
	if not Globals.changeSkinIdThrottle then
		Globals.changeSkinIdThrottle = true

		-- Validate
		if not (caller == Tooling.getOwner() and tonumber(amount)) then
			return
		end

		-- Get new skin id of the pie model
		local oldSkinId = Tooling.pieModel:GetAttribute("EquippedSkinId")
		local newSkinId = (oldSkinId + amount - 1) % (#Globals.pieSkinsTable) + 1
		if not Globals.pieSkinsTable[newSkinId] then
			return
		end

		-- Remove old skin
		setSkinIdTo(newSkinId)

		Globals.changeSkinIdThrottle = false
	end
end


----- Skin setup -----

setUpPieSkin = function(skin: Model)
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
		rigidConstraint.Attachment1 = Tooling.pieMainPartAttachment
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

setUpPieSkinsTable = function()
	Globals.changeSkinIdThrottle = true

	-- Set reference properties
	for _, skinModel in Tooling.pieSkinsFolder:GetChildren() do
		if SkinUtil.getIsSkinModel(skinModel) then
			setUpPieSkin(skinModel)
		end
	end

	-- Record valid pie skins from folder
	local validPieSkinsInfo = {} :: {SkinInfo}
	for _, skinModel in Tooling.pieSkinsFolder:GetChildren() do
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
	Globals.pieSkinsTable = {} :: {SkinInfo}
	for _, pieSkinInfo in validPieSkinsInfo do
		table.insert(Globals.pieSkinsTable, pieSkinInfo)
	end

	Globals.changeSkinIdThrottle = false
end

onNewSkinsAdded = function(skin: Instance)
	-- Debounce
	-- If many skins are added in a short period (1 frame),
	-- wait until the last one is added, then proceed with the following code
	local debounceId = HttpService:GenerateGUID()
	Globals.skinAddedDebounceId = debounceId
	task.wait()

	-- Check if debounce changed
	if Globals.skinAddedDebounceId ~= debounceId then
		return
	end

	-- Store equipped skin id
	local oldSkinId = Tooling.pieModel:GetAttribute("EquippedSkinId")
	local realSkinId = Globals.pieSkinsTable[oldSkinId] and Globals.pieSkinsTable[oldSkinId].Id or 0

	-- Used saved skin id if possible
	local player = Tooling.getOwner()
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

loadSavedSkin = function()
	-- Check variable
	local player = Tooling.getOwner()

	-- Populate skins
	if player then
		PieSkinsApi.populateToolSkins(Tooling.tool)
	end

	-- Switch skin
	local userId = player and player.UserId
	if userId then
		local savedRealSkinId = PieSkinsApi.getUserSkinId(userId)
		if savedRealSkinId then
			setRealSkinIdTo(savedRealSkinId, true)
		end
	end
end

initSetUp = function()
	setUpPieSkinsTable()
	setSkinIdTo(Tooling.pieModel:GetAttribute("EquippedSkinId"), true)

	-- Events for changing skins
	Tooling.pieSkinsFolder.ChildAdded:Connect(onNewSkinsAdded)
	Tooling.pieSkinsFolder.ChildRemoved:Connect(onNewSkinsAdded)
end


----- Main -----

local function main()
	-- Parent changed
	Tooling.tool:GetPropertyChangedSignal("Parent"):Connect(loadSavedSkin)

	-- Remote events
	BelovedRemote.connect_toServer("Change Skin Id By", changeSkinIdBy)

	-- Set up
	loadSavedSkin()
	initSetUp()
end


---------- Calling function ----------

main()
