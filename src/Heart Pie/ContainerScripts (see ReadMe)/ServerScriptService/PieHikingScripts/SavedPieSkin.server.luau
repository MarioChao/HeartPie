--!strict
-- Saved Pie Skin Script

---------- Validate container ----------
-- Validate the script's container before running any code

-- For some server scripts
if not script:FindFirstAncestorWhichIsA("ServerScriptService") then
	return
end

---------- Services ----------

local ServerStorage = game:GetService("ServerStorage") or script.Parent.Parent.Parent.ServerStorage

---------- Imports ----------

local PieHikingServerStorage = ServerStorage:WaitForChild("PieHikingServerStorage")
local SavedSession = require(PieHikingServerStorage:WaitForChild("SavedSession"))

---------- Instances ----------

local PieHikingServerEvents = PieHikingServerStorage:WaitForChild("PieHikingServerEvents")
local SavedSkinBindableFunction = PieHikingServerEvents:WaitForChild("SavedSkinBindableFunction")
local SavedSkinBindableEvent = PieHikingServerEvents:WaitForChild("SavedSkinBindableEvent")

---------- Local functions ----------

local function saveUserSkinId(userId: number, skinId: number)
	return SavedSession.saveUserInfo(userId, skinId)
end

local function getUserSkinId(userId: number)
	return SavedSession.getUserSavedInfo(userId)
end

---------- Event functions ----------

local function onSavedSkinBindableInvoke(mode: string, ...)
	if mode == "Get Skin Id" then
		return getUserSkinId(...)
	end
end

local function onSavedSkinBindableEvent(mode: string, ...)
	if mode == "Save Skin Id" then
		saveUserSkinId(...)
	end
end

---------- Calling / connecting functions----------

SavedSkinBindableFunction.OnInvoke = onSavedSkinBindableInvoke
SavedSkinBindableEvent.Event:Connect(onSavedSkinBindableEvent)
