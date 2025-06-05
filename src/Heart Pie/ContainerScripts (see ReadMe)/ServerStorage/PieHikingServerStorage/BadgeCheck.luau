--!strict
-- Cached Badge Check Module Script


---------- Module ----------
local CachedBadgeCheck = {}


---------- Imports ----------

local PieHikingServerStorage = script.Parent
local BadgeCheckHelper = require(PieHikingServerStorage.BadgeCheckHelper)


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

function CachedBadgeCheck.checkUserHasBadge(userId: number, badgeId: number): boolean
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
	local fetchStatus = BadgeCheckHelper.userHasBadges(userId, {badgeId})[badgeId]

	-- Cache fetch
	if not badgeFetchInfos then
		badgeFetchInfos = {} :: {[number]: BadgeFetchInfo}
		userBadgeFetchInfos[userId] = badgeFetchInfos
	end
	badgeFetchInfos[badgeId] = createFetchInfo(fetchStatus, _expire_seconds)

	-- Return result
	return fetchStatus
end


---------- Call background functions ----------

task.defer(startCleanUp)


---------- Return module ----------
return CachedBadgeCheck
