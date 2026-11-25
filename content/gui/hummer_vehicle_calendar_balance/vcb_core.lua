-- Pure helpers for Vehicle Calendar Balance (no engine access, testable
-- offline). The engine-facing glue lives in vcb_balance.lua.
--
-- Why calendar dates: the base vehicle balance sums the last
-- api.util.getDefaultYearDuration() of game time (365 days x 4000 ms, about
-- 24 minutes), which is one calendar year only at calendar speed 1x; at 0.25x
-- it covers about 3 months. GAME_TIME.dates holds one { gameTime, Date } entry
-- per calendar day, so the game time at which "the same day one year ago"
-- began can be looked up at any calendar speed, across speed changes too.
-- (The same idea as Square Line Manager Plus does for line balances.)
local M = {}

M.SEARCH_CAP = 64 -- binary search steps (2^64 entries)

local function finite(v)
	return type(v) == "number" and v == v and v > -math.huge and v < math.huge
end

--- y * 10000 + m * 100 + d and the game time of a dates entry, or nil.
function M.entryKey(e)
	if type(e) ~= "table" and type(e) ~= "userdata" then return nil end
	local ok, t, key = pcall(function()
		local d = e[2]
		return e[1], d.year * 10000 + d.month * 100 + d.day
	end)
	if ok and finite(t) and finite(key) then return key, t end
	return nil
end

--- Start of the last calendar year for `now` from `dates` ({ { gameTime,
--- Date }, ... } ascending), or nil when the table can't be used.
--- Returns start, clamped (the game is younger than a year: the first entry).
--- The start keeps the same time of day as now (now - newest entry's time),
--- so the window does not jump once per calendar day.
function M.lastYearStart(dates, now)
	if not finite(now) then return nil end
	local okN, n = pcall(function() return #dates end)
	if not okN or not finite(n) or n < 1 then return nil end
	local lastKey, lastT = M.entryKey(dates[n])
	local firstKey, firstT = M.entryKey(dates[1])
	if lastKey == nil or firstKey == nil or lastT > now then return nil end
	local target = lastKey - 10000
	if target < firstKey then return firstT, true end
	-- the last entry whose date is <= target (Feb 29 back to a common year: Feb 28)
	local lo, hi, steps = 1, n, 0
	while lo < hi and steps < M.SEARCH_CAP do
		steps = steps + 1
		local mid = math.floor((lo + hi + 1) / 2)
		local key = M.entryKey(dates[mid])
		if key == nil then return nil end
		if key <= target then lo = mid else hi = mid - 1 end
	end
	if lo ~= hi then return nil end
	local _key, t = M.entryKey(dates[lo])
	return math.min(t + (now - lastT), now), false
end

--- The base window start: one default year back, not before the game start.
function M.defaultStart(now, year)
	return math.max(now - year, 0)
end

return M
