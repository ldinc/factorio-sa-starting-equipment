-- Shared helpers for the FactorioTest suites in this folder.
local util = require("util")

local M = {}

M.SETTING = {
	list = "freeplay_starting_equipment_list",
	ignore = "freeplay_starting_equipment_ignore_remote_calls",
	append = "freeplay_starting_equipment_append_default_to_remote_calls",
}

M.INTERFACE = "ldinc_starting_equipment"

M.DEFAULT_LIST =
'modular-armor=1 personal-roboport-equipment=1 battery-equipment=3 solar-panel-equipment=15 firearm-magazine=50 construction-robot=10'

---Saves the mod's storage and runtime settings.
---@return fun() restore puts everything back exactly as it was
function M.snapshot()
	local saved_storage = util.table.deepcopy(storage.ldinc)
	local saved_settings = {}

	for _, name in pairs(M.SETTING) do
		saved_settings[name] = settings.global[name].value
	end

	return function()
		storage.ldinc = saved_storage

		for name, value in pairs(saved_settings) do
			if settings.global[name].value ~= value then
				settings.global[name] = { value = value }
			end
		end
	end
end

---Registers before_each/after_each hooks that snapshot and restore state around every test.
function M.isolate()
	local restore

	before_each(function()
		restore = M.snapshot()
		ldinc_starting_equipment.fn.on_init()
	end)

	after_each(function()
		if restore then
			restore()
			restore = nil
		end
	end)
end

---@param opts { list: string?, ignore: boolean?, append: boolean? }
function M.set_settings(opts)
	if opts.list ~= nil then
		settings.global[M.SETTING.list] = { value = opts.list }
	end

	if opts.ignore ~= nil then
		settings.global[M.SETTING.ignore] = { value = opts.ignore }
	end

	if opts.append ~= nil then
		settings.global[M.SETTING.append] = { value = opts.append }
	end
end

---Removes all lists registered by other mods through the remote API.
function M.clear_additional()
	ldinc_starting_equipment.fn.on_init()
	storage.ldinc.starting_equipment.additional = {}
end

return M
