local adns = require "prosody.net.adns";
local r = adns.resolver();

local function dns_escape(input)
	return (input:gsub("%W", "_"));
end
local render_hostname = require "prosody.util.interpolation".new("%b{}", dns_escape);

local update_dns = module:get_option_string("update_check_dns");
local check_interval = module:get_option_number("update_check_interval", 86400);

local mod_snikket_version = module:depends("snikket_version");

local version_info = {};

do
	local version_string = mod_snikket_version.snikket_version;
	-- "dev 128-00000", "release v2021.05r2", "release beta.20220119"
	local series, version = version_string:match("(%w+) (%S+)$");
	if series then
		version_info.branch, version_info.level = series, version:match("%d+%.?%d*");
	end
end

function check_for_updates()
	if not update_dns then return; end
	local record_name = render_hostname(update_dns, version_info);
	module:log("debug", "Checking for updates on %s...", record_name);
	r:lookup(function (records)
		if not records or #records == 0 then
			module:log("warn", "Update check failed for %s", record_name);
			return;
		end
		local result = {};
		for _, record in ipairs(records) do
			if record.txt then
				local key, val = tostring(record.txt):match("(%S+)=(%S+)");
				if key then
					result[key] = val;
				end
			end
		end
		module:log("debug", "Finished checking for updates");
		module:fire_event("update-check/result", { current = version_info, latest = result });
	end, record_name, "TXT", "IN");
	return check_interval;
end

function module.load()
	if update_dns then
		module:add_timer(5, check_for_updates);
	else
		module:log("warn", "Update notifications are disabled");
	end
end
