--!strict

-- Default Pie Skin Conditions


---------- Services ----------

local ReplicatedStorage = game:GetService("ReplicatedStorage")


---------- Imports ----------

local _PieHiking_SharedStorage = ReplicatedStorage:WaitForChild("PieHiking_SharedStorage")
local _Modules = _PieHiking_SharedStorage:WaitForChild("Modules")
local BadgeUtil = require(_Modules:WaitForChild("BadgeUtil"))


---------- Types ----------

type ConditionFunction = (userId: number) -> boolean


---------- Local functions ----------

local getUserHasBadges


----- Badge -----

getUserHasBadges = function(userId: number, badgeIds: {number})
	local checkResult = BadgeUtil.CachedBadgeCheck.checkUserHasBadges(userId, badgeIds)
	local result = true
	for _, badgeId in badgeIds do
		if not checkResult[badgeId] then
			result = false
			break
		end
	end
	return result
end


---------- Module ----------

local Conditions: {[string]: ConditionFunction} = {}


----- Conditions -----

Conditions["Heart"] = function(userId: number)
	return userId == 417781436 or true
end

Conditions["Rhubarb"] = function(userId: number)
	return getUserHasBadges(userId, {2124874992})
end


---------- Return module ----------

table.freeze(Conditions)
return Conditions
