--!strict
-- Pie Skin Conditions Module Script

---------- Imports ----------

local BadgeCheck = require(script.Parent:WaitForChild("BadgeCheck"))

---------- Types ----------

type ConditionFunction = (userId: number) -> boolean

---------- Conditions module ----------
local Conditions: {[string]: ConditionFunction} = {}

---------- Helper functions ----------

local userHasBadge = BadgeCheck.checkUserHasBadge

---------- Conditions ----------

Conditions["Heart"] = function(userId: number)
	return userId == 417781436 or true
end

Conditions["Rhubarb"] = function(userId: number)
	return userHasBadge(userId, 2124874992)
end

---------- Return module ----------
return Conditions
