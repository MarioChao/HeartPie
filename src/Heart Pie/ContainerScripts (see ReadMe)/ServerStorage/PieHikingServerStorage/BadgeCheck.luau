--!strict
-- Badge Check Module Script

---------- Module ----------
local BadgeCheck = {}

---------- Services ----------

local BadgeService = game:GetService("BadgeService")

---------- Types ----------

type CacheStatus = {
	cachedTime_seconds: number,
	expire_seconds: number,
	timeFunc: () -> number,
}

type BadgeFetchInfo = {
	fetchStatus: boolean,
	cacheStatus: CacheStatus,
}

---------- Variables ----------

local userBadgeFetchInfos: {[number]: {[number]: BadgeFetchInfo}} = {}
local _expire_seconds = 352 -- around 6 minutes

---------- Helper functions ----------

local function isCacheExpired(cache: CacheStatus)
	local expireTime = cache.cachedTime_seconds + cache.expire_seconds
	return cache.timeFunc() > expireTime
end

local function createCache(expire_seconds: number, timeFunc: (() -> number)?)
	if not timeFunc then
		timeFunc = time
	end

	local newCache: CacheStatus = {
		cachedTime_seconds = timeFunc(),
		expire_seconds = expire_seconds,
		timeFunc = timeFunc,
	}
	return newCache
end

local function createFetchInfo(fetchStatus: boolean, expire_seconds: number)
	local newFetchInfo: BadgeFetchInfo = {
		fetchStatus = fetchStatus,
		cacheStatus = createCache(expire_seconds),
	}
	return newFetchInfo
end

local function userHasBadges(userId: number, badgeIds: {number}): {[number]: boolean}
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

	-- Multiple badge ids
	do
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

		-- Build check result
		local checkResult: {[number]: boolean} = {}
		for _, badgeId in result do
			checkResult[badgeId] = true
		end
		for _, badgeId in badgeIds do
			if not checkResult[badgeId] then
				checkResult[badgeId] = false
			end
		end

		-- Return check result
		return checkResult
	end

end

---------- Clean up functions ----------

local function cleanUpFetches()
	for userId, fetchInfos in userBadgeFetchInfos do
		for badgeId, fetchInfo in fetchInfos do
			if isCacheExpired(fetchInfo.cacheStatus) then
				fetchInfos[badgeId] = nil
			end
		end
		if #fetchInfos == 0 then
			userBadgeFetchInfos[userId] = nil
		end
	end
end

local function startCleanUp()
	while true do
		task.wait(_expire_seconds * 2)
		cleanUpFetches()
	end
end

---------- Module functions ----------

function BadgeCheck.checkUserHasBadge(userId: number, badgeId: number): boolean
	-- Sanitize input
	userId = tonumber(userId)
	badgeId = tonumber(badgeId)
	if not (userId and badgeId) then
		return
	end

	-- Check cached result
	local badgeFetchInfos = userBadgeFetchInfos[userId]
	local fetchInfo = badgeFetchInfos and badgeFetchInfos[badgeId]
	local isFetchValid = (
		fetchInfo and not isCacheExpired(fetchInfo.cacheStatus)
	)
	if isFetchValid then
		return fetchInfo.fetchStatus
	end

	-- Do a new fetch
	local fetchStatus = userHasBadges(userId, {badgeId})[badgeId]

	-- Cache fetch
	if not badgeFetchInfos then
		badgeFetchInfos = {} :: {[number]: BadgeFetchInfo}
		userBadgeFetchInfos[userId] = badgeFetchInfos
	end
	badgeFetchInfos[badgeId] = createFetchInfo(fetchStatus, _expire_seconds)

	-- Return result
	return fetchStatus
end

BadgeCheck.userHasBadges = userHasBadges

---------- Call background functions ----------

task.defer(startCleanUp)

---------- Return module ----------
return BadgeCheck
