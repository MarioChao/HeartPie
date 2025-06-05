--!strict
-- Badge Check Module Script


---------- Module ----------
local BadgeCheck = {}


---------- Services ----------

local BadgeService = game:GetService("BadgeService")


---------- Types ----------

type BadgeCheckResult = {[number]: boolean}


---------- Variables ----------

local _badgeBatchSize = 10


---------- Local functions ----------

local function userHasBadges(userId: number, badgeIds: {number}): BadgeCheckResult
	-- No badge ids provided
	if not badgeIds or #badgeIds == 0 then
		return {}
	end

	-- Only one badge id
	if #badgeIds == 1 then
		local badgeId = badgeIds[1]
		local tries = 0
		local success, result
		repeat
			success, result = pcall(function()
				return BadgeService:UserHasBadgeAsync(userId, badgeId)
			end)
			tries += 1
		until success or tries >= 5

		-- Sanitize result
		result = if success and result then true else false
		return {[badgeId] = result}
	end

	-- At most batch-size badge ids
	if #badgeIds <= _badgeBatchSize then
		local tries = 0
		local success, result
		repeat
			success, result = pcall(function()
				return BadgeService:CheckUserBadgesAsync(userId, badgeIds)
			end)
			tries += 1
		until success or tries >= 5

		-- Sanitize result
		result = if success then result else {}


		---------- Build check result ----------

		local checkResult: BadgeCheckResult = {}

		-- Awarded badges
		for _, badgeId in result do
			checkResult[badgeId] = true
		end

		-- Unawarded badges
		for _, badgeId in badgeIds do
			if not checkResult[badgeId] then
				checkResult[badgeId] = false
			end
		end


		-- Return check result
		return checkResult
	end

	-- Many badge ids
	do
		-- Group badges into batches
		local badgeIdBatches: {{number}} = {}
		local temporaryBatch = {}
		for _, badgeId in badgeIds do
			-- Insert batch and create new empty batch
			if #temporaryBatch >= _badgeBatchSize then
				table.insert(badgeIdBatches, temporaryBatch)
				temporaryBatch = {}
			end

			-- Store id in the batch
			table.insert(temporaryBatch, badgeId)
		end
		-- Insert final batch
		table.insert(badgeIdBatches, temporaryBatch)

		-- Check by batches
		local batchCheckResults: {BadgeCheckResult} = {}
		for _, idBatch in badgeIdBatches do
			local batchCheckResult = userHasBadges(userId, idBatch)
			table.insert(batchCheckResults, batchCheckResult)
		end

		-- Combine batch results
		local checkResult: BadgeCheckResult = {}
		for _, batchCheckResult in batchCheckResults do
			for badgeId, isAwarded in batchCheckResult do
				checkResult[badgeId] = isAwarded
			end
		end

		-- Return check result
		return checkResult
	end
end


---------- Module functions ----------

BadgeCheck.userHasBadges = userHasBadges


---------- Return module ----------
return BadgeCheck
