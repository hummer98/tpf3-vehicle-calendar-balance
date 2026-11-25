-- Vehicle Calendar Balance: the vehicle balance ("Last Year") over the last
-- calendar year instead of the default-speed year.
--
-- Where: the base recipe vehicle_react_util.VehicleBalance is used by the
-- vehicle window's "Last Year" (vehicle_eow.script.tl:764) and the Statistics
-- window's vehicles table (statistic_vehicles.tl:296, one per row). Both look
-- the recipe up in the module table on every render, so the module field is
-- wrapped: a plain call with one params table renders our recipe, any other
-- call (a ref, meta) goes to the base unchanged. Not changed: the Statistics
-- table's Balance sort (a local function, statistic_vehicles.tl:324),
-- UI Overhaul's statistics vehicles total, sort and "losing" filter, and
-- Square Line Manager Plus's vehicle hover panel, which compute their own
-- over the default year.
-- A ReplaceRecipe of VehicleBalance by another mod is not rendered for the
-- plain calls we take over (none of the installed mods does one).
--
-- Our recipe rebuilds the base tree (a horizontal BoxLayout holding a TextView
-- "font-scale-body, positive|negative", forceFocusable); no CSS names the
-- VehicleBalance recipe, so nothing styled is lost. When the calendar dates
-- can't be read the base window (one default year) is used, so the cell
-- always shows a value.
local core = require "hummer_vehicle_calendar_balance::/gui/hummer_vehicle_calendar_balance/vcb_core.lua"

local M = {}

M.VRU = "::/gui/line_vehicle_mgmt/vehicle_react_util.tl"
M.ENGINE = "::/gui/main/engine_react_util.tl"
M.RECIPE = "VcbVehicleBalance"

local reported = {}
local function reportOnce(key, msg)
	if reported[key] then return end
	reported[key] = true
	pcall(debugPrint, "[VCB] " .. msg)
end

-- The window start depends only on the dates table and now, not on the
-- vehicle, so one lookup serves every row of the Statistics table: cached
-- until a new date entry appears, the start then moves with now. Every row
-- polls at the same game time, so the start is also memoised per `now`: one
-- read of the dates table per poll, not one per row.
local cal = nil -- { n, lastT, base = now when computed, start, clamped }
local memo = nil -- { now, start }

function M.reset() cal = nil; memo = nil end

-- Known limits (kept as the line balance of Square Line Manager Plus does, so
-- line and vehicle "Last Year" stay comparable):
--  * the start keeps today's elapsed game ms on the day a year ago; across a
--    calendar speed change this shifts it by up to one day's ms (< 1 %).
--  * with the calendar paused before the first year is complete, the window
--    stays at the game start, i.e. everything is "this calendar year".

--- Window start for the GAME_TIME component `c`: the calendar year, else the
--- default year. Errors propagate.
function M.windowStart(c, year)
	local now = c.gameTime
	if memo ~= nil and memo.now == now then return memo.start end
	local start = M.calendarStart(c, now)
	if start ~= nil then
		memo = { now = now, start = start }
		return start
	end
	reportOnce("fallback", "calendar dates unusable, using the default year")
	return core.defaultStart(now, year)
end

--- The calendar-year start for `now`, or nil when the dates can't be used.
function M.calendarStart(c, now)
	local ok, dates = pcall(function() return c.dates end)
	if ok and dates ~= nil then
		local okN, n = pcall(function() return #dates end)
		if okN and type(n) == "number" and n > 0 then
			local _key, lastT = core.entryKey(dates[n])
			if cal ~= nil and cal.n == n and cal.lastT == lastT and lastT ~= nil and lastT <= now and now >= cal.base then
				if cal.clamped then return cal.start end
				return math.min(cal.start + (now - cal.base), now)
			end
			local start, clamped = core.lastYearStart(dates, now)
			if start ~= nil then
				cal = { n = n, lastT = lastT, base = now, start = start, clamped = clamped }
				return start
			end
		end
	end
	return nil
end

--- The balance of `vehicle` over the last calendar year. Errors propagate.
function M.balance(vehicle)
	local c = api.engine.getComponent(api.engine.util.getWorld(), api.type.ComponentType.GAME_TIME)
	local now = c and c.gameTime
	if type(now) ~= "number" or now ~= now then error("no game time") end
	local year = api.util.getDefaultYearDuration()
	local from = M.windowStart(c, year)
	return api.engine.util.finance.calculateBalance({ vehicle }, from, now, true)
end

-- the base window, for when ours fails (the value the base would show)
local function baseBalance(vehicle)
	local c = api.engine.getComponent(api.engine.util.getWorld(), api.type.ComponentType.GAME_TIME)
	local now = c.gameTime
	local from = core.defaultStart(now, api.util.getDefaultYearDuration())
	return api.engine.util.finance.calculateBalance({ vehicle }, from, now, true)
end

function M.value(vehicle)
	local ok, v = pcall(M.balance, vehicle)
	if ok and type(v) == "number" then return v end
	reportOnce("value", "calendar balance failed: " .. tostring(v))
	return baseBalance(vehicle)
end

local prev = {}      -- prev.fn: the VehicleBalance we wrapped
local recipe = nil
local mods = nil     -- builtin, engine_react_util of this load

--- Body of our recipe, as vehicle_react_util.tl:414-433 with our value.
function M.body(p)
	local makeState = function() return M.value(p.entity) end
	local eru = mods.engine_react_util
	-- stepTimer is fixed per instance (as in the base), so the hook order holds
	local state = p.stepTimer and eru.useStepStateTimer(makeState) or eru.useStepState(makeState)
	local v = state:old() or 0
	return mods.builtin.BoxLayout{
		orientation = mods.builtin.type.Orientation.Horizontal,
		children = {
			mods.builtin.TextView{
				meta = { class = "font-scale-body, " .. ((v < 0) and "negative" or "positive"), forceFocusable = true },
				text = api.util.formatMoney(v),
			},
		},
	}
end

local function vehicleBalance(p, ...)
	if recipe ~= nil and select("#", ...) == 0 and type(p) == "table" and p.meta == nil and p.entity ~= nil then
		return recipe{ entity = p.entity, stepTimer = p.stepTimer }
	end
	return prev.fn(p, ...)
end

-- a later ReplaceRecipe(<our wrapper>, x) gets the function we wrapped
local function shimReplacementApi(replacementApi)
	if type(replacementApi) ~= "table" then return end
	local replace = replacementApi.ReplaceRecipe
	if type(replace) ~= "function" then return end
	replacementApi.ReplaceRecipe = function(original, ...)
		if original == vehicleBalance then original = prev.fn end
		return replace(original, ...)
	end
end

--- Wraps vehicle_react_util.VehicleBalance. Called at UI bootstrap; runs
--- again on every game load, when the GUI modules are loaded afresh, so
--- "already done" is told by the field in place.
function M.install(ug, replacementApi)
	local vru = ug(M.VRU)
	local fn = type(vru) == "table" and vru.VehicleBalance or nil
	if fn == vehicleBalance then return end
	if type(fn) ~= "function" and type(fn) ~= "table" then error("VehicleBalance is " .. type(fn)) end
	local eru = ug(M.ENGINE)
	if type(eru) ~= "table" or type(eru.useStepStateTimer) ~= "function" or type(eru.useStepState) ~= "function" then
		error("engine_react_util hooks missing")
	end
	local react = ug "::/gui/main/react.lua"
	mods = { builtin = ug "::/gui/main/builtin.lua", engine_react_util = eru }
	recipe = react.RegisterRecipe(M.RECIPE, M.body)
	prev.fn = fn
	M.reset()
	vru.VehicleBalance = vehicleBalance
	shimReplacementApi(replacementApi)
end

return M
