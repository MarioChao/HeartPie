--!strict
-- Server Pie Skins Script

---------- Services ----------

local Debris = game:GetService("Debris")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

---------- Types ----------

type SkinInfo = {Id: number, Model: Model}

---------- Instances ----------

local Tool = script.Parent.Parent.Parent
local ToolEvents = Tool:WaitForChild("ToolEvents")
local PieSkinRemoteEvent = ToolEvents:WaitForChild("PieSkinRemoteEvent")
local ToolVisualEvent = ToolEvents:WaitForChild("ToolVisualEvent")

local PieHikingServerEvents = ServerStorage:WaitForChild("PieHikingServerEvents")
local ConditionalSkinsBindableEvent: BindableEvent = PieHikingServerEvents:WaitForChild("ConditionalSkinsBindableEvent")

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

---------- Local functions ----------

---------- Skin id functions ----------

local function setSkinIdTo(newSkinId: number)
	-- Validate skin
	newSkinId = (newSkinId - 1) % (#pieSkinsTable) + 1
	if not pieSkinsTable[newSkinId] then
		return
	end

	-- Remove old skin
	task.synchronize()
	local oldPieSkinFolder = PieModel:FindFirstChild("PieSkin")
	if oldPieSkinFolder then
		Debris:AddItem(oldPieSkinFolder, 0)
	end

	-- Update new skin
	PieModel:SetAttribute("EquippedSkinId", newSkinId)
	local newPieSkinFolder = Instance.new("Folder")
	newPieSkinFolder.Name = "PieSkin"
	local newPieSkin = pieSkinsTable[newSkinId].Model:Clone()
	newPieSkin.Parent = newPieSkinFolder

	newPieSkinFolder.Parent = PieModel -- Might cause exception

	-- Update Tool properties
	local newToolTextureId: string = newPieSkin:GetAttribute("ToolTextureId")
	if newToolTextureId then
		Tool.TextureId = newToolTextureId
	end
	local newToolTip: string = newPieSkin:GetAttribute("ToolTip")
	if newToolTip then
		Tool.ToolTip = newToolTip
	end

	-- Renew transparency
	ToolVisualEvent:Fire("Renew Pie Transparency")
end

local function changeSkinIdBy(caller: Player, amount: number)
	if not changeSkinIdThrottle then
		changeSkinIdThrottle = true
		task.delay(0.2, function()
			changeSkinIdThrottle = false
		end)

		-- Validate
		task.desynchronize()
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
	end
end

---------- Skin setup functions ----------

local function setUpSkinReferences(skin: Model)
    -- Validate skin main part
    local skinMainPart = skin:FindFirstChild("SkinMainPart")
    if not (skinMainPart and skinMainPart:IsA("Part")) then
        return
    end

    -- Get attachment
    local skinAttachment = skinMainPart:WaitForChild("PieSkinAttachment")

    -- Set up rigid constraint
    local rigidConstraint = skinMainPart:WaitForChild("RigidConstraint")
    rigidConstraint.Attachment0 = skinAttachment
    rigidConstraint.Attachment1 = PieMainPartAttachment
end

local function setUpPieSkinsTable()
	changeSkinIdThrottle = true

	-- Set reference properties
	task.synchronize()
	for _, pieSkin: Instance in PieSkins:GetChildren() do
		setUpSkinReferences(pieSkin)
	end

	-- Record valid pie skins from folder
	task.desynchronize()
	local validPieSkinsInfo = {} :: {SkinInfo}
	for _, pieSkin in PieSkins:GetChildren() do
		-- Validate pie skin
		local skinId = pieSkin:GetAttribute("SkinId")
		if not (pieSkin:IsA("Model") and skinId) then
			continue
		end

		-- Add to valid pie skins
		local skinInfo = {["Id"] = skinId, ["Model"] = pieSkin}
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
	local realSkinId = pieSkinsTable[oldSkinId].Id

	-- Refresh pie skins table
	setUpPieSkinsTable()

	-- Equip the original pie skin
	local newSkinId = 1
	for id, pieSkinInfo in pieSkinsTable do
		if pieSkinInfo.Id == realSkinId then
			newSkinId = id
			break
		end
	end
	-- print(`Old: {oldSkinId}, real: {realSkinId}, new: {newSkinId}`)
	setSkinIdTo(newSkinId)
end

local function onToolEquipped()
	character = Tool.Parent
	player = character and Players:GetPlayerFromCharacter(character)
	if player then
		ConditionalSkinsBindableEvent:Fire("Populate Tool Skins", Tool)
	end
end

local function onToolUnequipped()
	character = nil
	player = nil
end

local function initSetUp()
	setUpPieSkinsTable()
	setSkinIdTo(PieModel:GetAttribute("EquippedSkinId"))

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
