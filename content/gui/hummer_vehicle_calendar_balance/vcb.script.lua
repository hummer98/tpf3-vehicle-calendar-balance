-- Vehicle Calendar Balance: the replacement-config hook (vcb.res.lua).
-- A failure leaves the base vehicle balance as it was and logs one line.
local balance = require "hummer_vehicle_calendar_balance::/gui/hummer_vehicle_calendar_balance/vcb_balance.lua"

local function VCB_Install(replacementApi)
	local ok, err = pcall(balance.install, ug_require, replacementApi)
	if not ok then debugPrint("[VCB] install: " .. tostring(err)) end
end

-- The engine loads *.script.lua resources by calling data().
function data()
	return { VCB_Install = VCB_Install }
end
