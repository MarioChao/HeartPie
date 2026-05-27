--!strict
-- Cached Badge Check Module Script


---------- Module ----------

local CachedBadgeCheck = {}


---------- Imports ----------

local BadgeCheckHelper = require(script.Parent.BadgeCheckHelper)


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
local _expire_seconds = 64 -- around 1 minute


---------- Cache functions ----------

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


---------- Clean up functions ----------

local function cleanUpFetches()
	for userId, fetchInfos in userBadgeFetchInfos do
		-- Clear expired badge results
		for badgeId, fetchInfo in fetchInfos do
			if isCacheExpired(fetchInfo.cacheStatus) then
				fetchInfos[badgeId] = nil
			end
		end

		-- Clear user table if empty
		if not next(fetchInfos) then
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


---------- Local functions ----------

local function getCached(userId: number, badgeId: number)
	-- Check cache table
	local badgeFetchInfos = userBadgeFetchInfos[userId]
	local fetchInfo = badgeFetchInfos and badgeFetchInfos[badgeId]
	local isFetchValid = (
		fetchInfo and not isCacheExpired(fetchInfo.cacheStatus)
	)

	-- Return result
	if isFetchValid then
		return true, fetchInfo.fetchStatus
	end
	return false
end

local function fetchAndCache(userId: number, badgeIds: {number})
	-- Do a new fetch
	local fetchStatuses = BadgeCheckHelper.userHasBadges(userId, badgeIds)

	-- Initialize player's cache
	local badgeFetchInfos = userBadgeFetchInfos[userId]
	if not badgeFetchInfos then
		badgeFetchInfos = {} :: {[number]: BadgeFetchInfo}
		userBadgeFetchInfos[userId] = badgeFetchInfos
	end

	-- Cache successful results
	for badgeId, result in fetchStatuses do
		badgeFetchInfos[badgeId] = createFetchInfo(result, _expire_seconds)
	end

	-- Return result
	return fetchStatuses
end


---------- Module functions ----------

function CachedBadgeCheck.userHasBadges(userId: number, badgeIds: {number}): BadgeCheckHelper.BadgeCheckResult
	-- Sanitize input
	userId = tonumber(userId)
	if not userId then
		return {}
	end

	-- Initialize result
	local checkResult: BadgeCheckHelper.BadgeCheckResult = {}

	-- Get uncached badge ids
	local uncachedBadgeIds: {number} = {}
	for _, badgeId in badgeIds do
		-- Store & skip cached result
		local cacheIsValid, cacheResult = getCached(userId, badgeId)
		if cacheIsValid then
			checkResult[badgeId] = cacheResult
			continue
		end

		-- Store uncached badge ids
		table.insert(uncachedBadgeIds, badgeId)
	end

	-- Fetch and cache
	local fetchStatuses = fetchAndCache(userId, uncachedBadgeIds)

	-- Store results
	for badgeId, isAwarded in fetchStatuses do
		checkResult[badgeId] = isAwarded
	end

	-- Return result
	return checkResult
end

function CachedBadgeCheck.checkUserHasBadge(userId: number, badgeId: number)
	return CachedBadgeCheck.userHasBadges(userId, {badgeId})[badgeId]
end


---------- Call background functions ----------

task.defer(startCleanUp)


---------- Return module ----------

return CachedBadgeCheck
