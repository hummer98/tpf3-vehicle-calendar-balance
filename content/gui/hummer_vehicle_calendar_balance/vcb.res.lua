-- Vehicle Calendar Balance: wraps the vehicle balance recipe at UI bootstrap
-- (vcb_balance.lua).
function data()
	return {
		type = "react-replacement-config",
		data = {
			filePath = "hummer_vehicle_calendar_balance::/gui/hummer_vehicle_calendar_balance/vcb.script",
			doReplaceFn = "VCB_Install",
		},
	}
end
