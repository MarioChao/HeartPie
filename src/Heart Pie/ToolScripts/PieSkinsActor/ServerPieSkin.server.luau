--!strict
-- Server Pie Skins Script

-- Tool info
local Tool = script.Parent.Parent.Parent
local ToolEvents = Tool:WaitForChild("ToolEvents")
local PieSkinRemoteEvent = ToolEvents:WaitForChild("PieSkinRemoteEvent")
local ToolVisualEvent = ToolEvents:WaitForChild("ToolVisualEvent")

local PieModel = Tool:WaitForChild("PieModel")

local PieSkins = Tool:WaitForChild("PieSkins")

-- Services
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

-- Variables
local pieSkinsTable: {[number]: Model}

local character: Model? = nil
local player: Player? = nil

local changeSkinIdThrottle = false

-- Functions
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
		Debris:AddItem(oldPieSkinFolder,0)
	end

	-- Update new skin
	PieModel:SetAttribute("EquippedSkinId", newSkinId)
	local newPieSkinFolder = Instance.new("Folder")
	newPieSkinFolder.Name = "PieSkin"
	local newPieSkin = pieSkinsTable[newSkinId]:Clone()
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

local function setupPieSkinsTable()
	changeSkinIdThrottle = true

	-- Record valid pie skins
	task.desynchronize()
	local validPieSkinsInfo = {} :: {{["Id"]: number, ["Model"]: Model}}
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
	pieSkinsTable = {}
	for _, pieSkinInfo in validPieSkinsInfo do
		table.insert(pieSkinsTable, pieSkinInfo.Model)
	end

	changeSkinIdThrottle = false
end

local function onToolEquipped()
	character = Tool.Parent
	player = character and Players:GetPlayerFromCharacter(character)
end

local function onToolUnequipped()
	character = nil
	player = nil
end

-- Event functions
local function onPieSkinServerEvent(caller: Player, mode: string, ...)
	if mode == "Change Skin Id By" then
		changeSkinIdBy(caller, ...)
	end
end

-- Calling / connecting functions
Tool.Equipped:Connect(onToolEquipped)
Tool.Unequipped:Connect(onToolUnequipped)
PieSkinRemoteEvent.OnServerEvent:Connect(onPieSkinServerEvent)
setupPieSkinsTable()
setSkinIdTo(PieModel:GetAttribute("EquippedSkinId"))
