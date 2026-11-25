-- Offline tests for Vehicle Calendar Balance. Run from anywhere:
--   luajit tests/run.lua
-- The game globals (api, ug_require, debugPrint) and GUI modules are stubbed
-- with just enough behaviour.

local root = (arg and arg[0] or "tests/run.lua"):match("^(.*)/tests/[^/]*$") or "."

local loaders = package.loaders or package.searchers
table.insert(loaders, 2, function(name)
	local rel = name:match("^hummer_vehicle_calendar_balance::/(.*)$")
	if rel then return assert(loadfile(root .. "/content/" .. rel)) end
end)

local failures, passes = 0, 0
local function test(name, fn)
	local ok, err = pcall(fn)
	if ok then
		passes = passes + 1
		print("PASS " .. name)
	else
		failures = failures + 1
		print("FAIL " .. name .. "\n     " .. tostring(err))
	end
end
local function eq(a, b, msg)
	if a ~= b then error((msg or "values differ") .. ": " .. tostring(a) .. " ~= " .. tostring(b), 2) end
end

local core = require "hummer_vehicle_calendar_balance::/gui/hummer_vehicle_calendar_balance/vcb_core.lua"

-- dates: one entry per day from (y, m, d), each day `ms` of game time
local DAYS = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
local function isLeap(y) return (y % 4 == 0 and y % 100 ~= 0) or y % 400 == 0 end
local function makeDates(y, m, d, count, ms, t0)
	local out, t = {}, t0 or 0
	for _i = 1, count do
		out[#out + 1] = { t, { year = y, month = m, day = d } }
		t = t + (type(ms) == "function" and ms(#out) or ms)
		d = d + 1
		local len = DAYS[m] + ((m == 2 and isLeap(y)) and 1 or 0)
		if d > len then d = 1; m = m + 1 end
		if m > 12 then m = 1; y = y + 1 end
	end
	return out
end

------------------------------------------------------------------------
-- core
------------------------------------------------------------------------
test("1x calendar (4000 ms/day): last year = 365 days of game time", function()
	local dates = makeDates(1900, 1, 1, 800, 4000)
	local now = dates[#dates][1] + 1000 -- 1 s into the newest day
	local start, clamped = core.lastYearStart(dates, now)
	eq(clamped, false)
	eq(now - start, 365 * 4000)
end)

test("0.25x calendar (16000 ms/day): last year = 365 days x 16000, 4x the default year", function()
	local dates = makeDates(1900, 1, 1, 800, 16000)
	local now = dates[#dates][1] + 500
	local start = core.lastYearStart(dates, now)
	eq(now - start, 365 * 16000)
end)

test("speed change inside the year: the window follows the dates", function()
	-- first 600 days at 4000, then 16000
	local dates = makeDates(1900, 1, 1, 800, function(i) return i <= 600 and 4000 or 16000 end)
	local now = dates[#dates][1]
	local start = core.lastYearStart(dates, now)
	-- newest entry index 800; one year back = index 435 (365 days earlier)
	eq(start, dates[435][1])
end)

test("leap year crossing: window spans 366 days when Feb 29 is inside", function()
	-- newest day 1905-03-01 (1904 is leap): one year back is 1904-03-01
	local dates = makeDates(1903, 1, 1, 790, 1000)
	local last = dates[#dates][2]
	local now = dates[#dates][1]
	local start = core.lastYearStart(dates, now)
	local key = last.year * 10000 + last.month * 100 + last.day
	-- find the entry exactly one year back
	local want
	for _i, e in ipairs(dates) do
		local d = e[2]
		if d.year * 10000 + d.month * 100 + d.day == key - 10000 then want = e[1] end
	end
	eq(start, want)
end)

test("Feb 29 back to a common year: lands on Feb 28", function()
	local dates = makeDates(1903, 1, 1, 425, 1000) -- ends 1904-02-29
	local last = dates[#dates][2]
	eq(last.month * 100 + last.day, 229, "fixture ends on Feb 29")
	local start = core.lastYearStart(dates, dates[#dates][1])
	local d
	for _i, e in ipairs(dates) do if e[1] == start then d = e[2] end end
	eq(d.year * 10000 + d.month * 100 + d.day, 19030228)
end)

test("game younger than a year: clamped to the first entry", function()
	local dates = makeDates(1900, 1, 1, 100, 4000, 50)
	local start, clamped = core.lastYearStart(dates, dates[100][1])
	eq(clamped, true)
	eq(start, 50)
end)

test("unusable dates: nil (empty, junk entry, newest after now, nil)", function()
	eq(core.lastYearStart({}, 10), nil)
	eq(core.lastYearStart(nil, 10), nil)
	eq(core.lastYearStart({ { 0, "x" } }, 10), nil)
	local dates = makeDates(1900, 1, 1, 10, 1000)
	eq(core.lastYearStart(dates, 0), nil)
	eq(core.lastYearStart(dates, 0 / 0), nil)
end)

test("defaultStart: one year back, not before 0", function()
	eq(core.defaultStart(5000, 1000), 4000)
	eq(core.defaultStart(500, 1000), 0)
end)

------------------------------------------------------------------------
-- vcb_balance with stubs
------------------------------------------------------------------------
local logs = {}
debugPrint = function(s) logs[#logs + 1] = s end

local DEFAULT_YEAR = 365 * 4000
local gt -- GAME_TIME component
local calls -- calculateBalance calls { from, to }
local function resetApi(dates, now)
	calls = {}
	gt = { gameTime = now, dates = dates }
	api = {
		engine = {
			getComponent = function(_e, ct) assert(ct == "GAME_TIME"); return gt end,
			util = {
				getWorld = function() return 0 end,
				finance = {
					calculateBalance = function(list, from, to, _x)
						calls[#calls + 1] = { from = from, to = to, entity = list[1] }
						return to - from -- the window length, so tests can read it back
					end,
				},
			},
		},
		type = { ComponentType = { GAME_TIME = "GAME_TIME" } },
		util = {
			getDefaultYearDuration = function() return DEFAULT_YEAR end,
			formatMoney = function(v) return "$" .. tostring(v) end,
		},
	}
end

local function newMods()
	local registered = {}
	local react = {
		registered = registered,
		RegisterRecipe = function(name, fn) registered[#registered + 1] = name; return fn end,
	}
	local builtin = {
		type = { Orientation = { Horizontal = "H" } },
		BoxLayout = function(p) return { kind = "BoxLayout", children = p.children, orientation = p.orientation } end,
		TextView = function(p) return { kind = "TextView", text = p.text, meta = p.meta } end,
	}
	local hookLog = {}
	local eru = {
		useStepState = function(f) hookLog[#hookLog + 1] = "step"; local v = f(); return { old = function() return v end } end,
		useStepStateTimer = function(f) hookLog[#hookLog + 1] = "timer"; local v = f(); return { old = function() return v end } end,
	}
	local baseCalls = {}
	local base = function(p, ...) baseCalls[#baseCalls + 1] = { p = p, n = select("#", ...) }; return { kind = "Base" } end
	local vru = { VehicleBalance = base }
	local files = {
		["::/gui/line_vehicle_mgmt/vehicle_react_util.tl"] = vru,
		["::/gui/main/engine_react_util.tl"] = eru,
		["::/gui/main/react.lua"] = react,
		["::/gui/main/builtin.lua"] = builtin,
	}
	return {
		ug = function(p) return assert(files[p], "unexpected require " .. p) end,
		vru = vru, base = base, baseCalls = baseCalls, hookLog = hookLog, react = react,
	}
end

local function freshBalance()
	package.loaded["hummer_vehicle_calendar_balance::/gui/hummer_vehicle_calendar_balance/vcb_balance.lua"] = nil
	return require "hummer_vehicle_calendar_balance::/gui/hummer_vehicle_calendar_balance/vcb_balance.lua"
end

test("0.25x: the cell sums the calendar year (4x the base window)", function()
	local dates = makeDates(1900, 1, 1, 800, 16000)
	resetApi(dates, dates[#dates][1] + 100)
	local b, m = freshBalance(), newMods()
	b.install(m.ug)
	local node = m.vru.VehicleBalance{ entity = 42, stepTimer = true }
	local tv = node.children[1]
	eq(tv.text, "$" .. tostring(365 * 16000))
	eq(calls[1].entity, 42)
	eq(calls[1].to, gt.gameTime)
	eq(m.hookLog[1], "timer")
end)

test("1x: same window length as the base (one default year)", function()
	local dates = makeDates(1900, 1, 1, 800, 4000)
	resetApi(dates, dates[#dates][1])
	local b, m = freshBalance(), newMods()
	b.install(m.ug)
	m.vru.VehicleBalance{ entity = 1 }
	eq(calls[1].to - calls[1].from, DEFAULT_YEAR)
	eq(m.hookLog[1], "step", "no stepTimer -> useStepState as the base")
end)

test("negative balance gets the negative class, positive the positive one", function()
	local dates = makeDates(1900, 1, 1, 800, 4000)
	resetApi(dates, dates[#dates][1])
	api.engine.util.finance.calculateBalance = function() return -5 end
	local b, m = freshBalance(), newMods()
	b.install(m.ug)
	local tv = m.vru.VehicleBalance{ entity = 1 }.children[1]
	eq(tv.meta.class, "font-scale-body, negative")
	eq(tv.meta.forceFocusable, true)
	api.engine.util.finance.calculateBalance = function() return 7 end
	eq(m.vru.VehicleBalance{ entity = 1 }.children[1].meta.class, "font-scale-body, positive")
end)

test("no dates: falls back to the default year (base value) and logs once", function()
	resetApi(nil, 10 * DEFAULT_YEAR)
	local b, m = freshBalance(), newMods()
	b.install(m.ug)
	local before = #logs
	m.vru.VehicleBalance{ entity = 1 }
	m.vru.VehicleBalance{ entity = 2 }
	eq(calls[1].from, 9 * DEFAULT_YEAR)
	local n = 0
	for i = before + 1, #logs do if logs[i]:find("default year") then n = n + 1 end end
	eq(n, 1)
end)

test("reading dates throws: default year", function()
	resetApi(nil, 3 * DEFAULT_YEAR)
	gt = setmetatable({ gameTime = 3 * DEFAULT_YEAR }, { __index = function(_t, k) if k == "dates" then error("no field") end end })
	local b, m = freshBalance(), newMods()
	b.install(m.ug)
	m.vru.VehicleBalance{ entity = 1 }
	eq(calls[1].from, 2 * DEFAULT_YEAR)
end)

test("our calculation failing: the base value is shown", function()
	local dates = makeDates(1900, 1, 1, 800, 16000)
	resetApi(dates, dates[#dates][1])
	local b, m = freshBalance(), newMods()
	b.install(m.ug)
	local n = 0
	api.engine.util.finance.calculateBalance = function(_l, from, to)
		n = n + 1
		if n == 1 then error("boom") end
		return to - from
	end
	local tv = m.vru.VehicleBalance{ entity = 1 }.children[1]
	eq(tv.text, "$" .. tostring(DEFAULT_YEAR))
end)

test("window cached per day: moves with now, recomputed on a new date entry", function()
	local dates = makeDates(1900, 1, 1, 800, 16000)
	local t = dates[#dates][1]
	resetApi(dates, t)
	local b, m = freshBalance(), newMods()
	b.install(m.ug)
	m.vru.VehicleBalance{ entity = 1 }
	gt.gameTime = t + 5000
	m.vru.VehicleBalance{ entity = 1 }
	eq(calls[2].to - calls[2].from, 365 * 16000, "same length later in the day")
	-- next day arrives
	dates[#dates + 1] = { t + 16000, { year = 1902, month = 3, day = 12 } }
	gt.gameTime = t + 16000
	m.vru.VehicleBalance{ entity = 1 }
	assert(calls[3].from > calls[2].from)
end)

-- dates behind a counter: reads of the dates field and of entries
local function countingGt(dates, now)
	local counts = { field = 0, entries = 0 }
	local proxy = setmetatable({}, {
		__index = function(_t, i) counts.entries = counts.entries + 1; return dates[i] end,
		__len = function() return #dates end,
	})
	local g = setmetatable({ gameTime = now }, {
		__index = function(_t, k) if k == "dates" then counts.field = counts.field + 1; return proxy end end,
	})
	return g, counts
end

test("many rows at the same game time read the dates once (memo per now)", function()
	local dates = makeDates(1900, 1, 1, 800, 16000)
	resetApi(nil, 0)
	local counts
	gt, counts = countingGt(dates, dates[#dates][1] + 10)
	local b, m = freshBalance(), newMods()
	b.install(m.ug)
	for e = 1, 50 do m.vru.VehicleBalance{ entity = e } end
	eq(counts.field, 1)
	eq(#calls, 50)
	for i = 1, 50 do eq(calls[i].to - calls[i].from, 365 * 16000) end
end)

test("later in the same day: no new binary search (cache per date entry)", function()
	local dates = makeDates(1900, 1, 1, 800, 16000)
	resetApi(nil, 0)
	local counts
	local t = dates[#dates][1]
	gt, counts = countingGt(dates, t)
	local b, m = freshBalance(), newMods()
	b.install(m.ug)
	m.vru.VehicleBalance{ entity = 1 }
	local firstEntries = counts.entries
	assert(firstEntries > 3, "first lookup searches")
	rawset(gt, "gameTime", t + 7000)
	m.vru.VehicleBalance{ entity = 1 }
	eq(counts.entries - firstEntries, 1, "only the newest entry is read")
	eq(calls[2].to - calls[2].from, 365 * 16000)
end)

test("install resets the caches (same now and entry count in another save)", function()
	local d1 = makeDates(1900, 1, 1, 800, 16000)
	local d2 = makeDates(1900, 1, 1, 800, function(i) return i <= 700 and 4000 or 16000 end)
	-- make both end at the same game time
	local shift = d1[#d1][1] - d2[#d2][1]
	for _i, e in ipairs(d2) do e[1] = e[1] + shift end
	resetApi(d1, d1[#d1][1])
	local b = freshBalance()
	b.install(newMods().ug)
	local m1 = newMods()
	b.install(m1.ug)
	m1.vru.VehicleBalance{ entity = 1 }
	resetApi(d2, d2[#d2][1])
	local m2 = newMods()
	b.install(m2.ug)
	m2.vru.VehicleBalance{ entity = 1 }
	eq(calls[1].from, d2[435][1], "window from the second save's dates")
end)

test("calendar paused: the window keeps its length and slides with game time", function()
	local dates = makeDates(1900, 1, 1, 800, 4000)
	local t = dates[#dates][1]
	resetApi(dates, t)
	local b, m = freshBalance(), newMods()
	b.install(m.ug)
	m.vru.VehicleBalance{ entity = 1 }
	gt.gameTime = t + 100000 -- no new date entry while paused
	m.vru.VehicleBalance{ entity = 1 }
	eq(calls[2].to - calls[2].from, 365 * 4000)
	eq(calls[2].to, t + 100000)
end)

test("calls with meta or a ref go to the base unchanged", function()
	local dates = makeDates(1900, 1, 1, 10, 4000)
	resetApi(dates, dates[#dates][1])
	local b, m = freshBalance(), newMods()
	b.install(m.ug)
	eq(m.vru.VehicleBalance{ entity = 1, meta = { x = 1 } }.kind, "Base")
	eq(m.vru.VehicleBalance("REF", { entity = 1 }).kind, "Base")
	eq(m.baseCalls[2].n, 1, "extra argument forwarded")
end)

test("install twice on the same module: wraps once", function()
	resetApi(makeDates(1900, 1, 1, 10, 4000), 40000)
	local b, m = freshBalance(), newMods()
	b.install(m.ug)
	local w = m.vru.VehicleBalance
	b.install(m.ug)
	eq(m.vru.VehicleBalance, w)
	eq(#m.react.registered, 1)
end)

test("next game load (fresh modules): wraps again and uses the new save's dates", function()
	local d1 = makeDates(1900, 1, 1, 800, 16000)
	resetApi(d1, d1[#d1][1])
	local b = freshBalance()
	local m1 = newMods()
	b.install(m1.ug)
	m1.vru.VehicleBalance{ entity = 1 }
	-- another save: same entry count, different times
	local d2 = makeDates(1953, 1, 1, 800, 4000) -- no Feb 29 in the last year
	resetApi(d2, d2[#d2][1])
	local m2 = newMods()
	b.install(m2.ug)
	assert(m2.vru.VehicleBalance ~= m2.base)
	m2.vru.VehicleBalance{ entity = 1 }
	eq(calls[1].to - calls[1].from, 365 * 4000)
end)

test("ReplaceRecipe on our wrapper is redirected to the wrapped base", function()
	resetApi(makeDates(1900, 1, 1, 10, 4000), 40000)
	local b, m = freshBalance(), newMods()
	local got
	local rapi = { ReplaceRecipe = function(orig) got = orig end }
	b.install(m.ug, rapi)
	rapi.ReplaceRecipe(m.vru.VehicleBalance, function() end)
	eq(got, m.base)
end)

test("install errors when VehicleBalance or hooks are missing", function()
	local b, m = freshBalance(), newMods()
	m.vru.VehicleBalance = nil
	eq((pcall(b.install, m.ug)), false)
end)

test("install script logs instead of throwing; res points at it", function()
	package.loaded["hummer_vehicle_calendar_balance::/gui/hummer_vehicle_calendar_balance/vcb_balance.lua"] = nil
	local m = newMods()
	m.vru.VehicleBalance = nil
	ug_require = m.ug
	dofile(root .. "/content/gui/hummer_vehicle_calendar_balance/vcb.script.lua")
	data().VCB_Install({})
	assert(logs[#logs]:find("%[VCB%] install:"), logs[#logs])
	dofile(root .. "/content/gui/hummer_vehicle_calendar_balance/vcb.res.lua")
	local d = data()
	eq(d.type, "react-replacement-config")
	eq(d.data.filePath, "hummer_vehicle_calendar_balance::/gui/hummer_vehicle_calendar_balance/vcb.script")
	eq(d.data.doReplaceFn, "VCB_Install")
end)

test("a working install and render log nothing (logs are for failures only)", function()
	local dates = makeDates(1900, 1, 1, 800, 16000)
	resetApi(dates, dates[#dates][1])
	local before = #logs
	local b, m = freshBalance(), newMods()
	b.install(m.ug, { ReplaceRecipe = function() end })
	for e = 1, 3 do m.vru.VehicleBalance{ entity = e, stepTimer = true } end
	eq(#logs, before, "no log line")
end)

test("calls without params or without an entity go to the base", function()
	resetApi(makeDates(1900, 1, 1, 10, 4000), 40000)
	local b, m = freshBalance(), newMods()
	b.install(m.ug)
	eq(m.vru.VehicleBalance(nil).kind, "Base")
	eq(m.vru.VehicleBalance{}.kind, "Base")
	eq(m.vru.VehicleBalance{ stepTimer = true }.kind, "Base")
	eq(#calls, 0, "our calculation not run")
end)

test("entryKey: nil, empty and partial entries are unusable", function()
	eq(core.entryKey(nil), nil)
	eq(core.entryKey({}), nil)
	eq(core.entryKey({ 5 }), nil)
	eq(core.entryKey({ 5, { year = 1900, month = 1 } }), nil)
	eq(core.entryKey({ 0 / 0, { year = 1900, month = 1, day = 1 } }), nil)
	local key, t = core.entryKey({ 5, { year = 1900, month = 2, day = 3 } })
	eq(key, 19000203)
	eq(t, 5)
end)

print(string.format("\n%d passed, %d failed", passes, failures))
os.exit(failures == 0 and 0 or 1)
