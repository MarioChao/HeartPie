--!strict
-- Saved Session Module Script

---------- Module ----------
local Session = {}

---------- Variables ----------

local userSavedInfo: {[number]: any} = {}

---------- Module functions ----------

function Session.getUserSavedInfo(userId: number)
	return userSavedInfo[userId]
end

function Session.saveUserInfo(userId: number, info: any)
	-- Sanitize input
	userId = tonumber(userId)
	if not userId then
		return
	end

	-- Save info
	userSavedInfo[userId] = info
end

---------- Return module ----------
return Session
