require('lib.script.items')
require('lib.script.settings')

---@param player LuaPlayer
function ldinc_starting_equipment.fn.check_starting_equipment(player)
	local items = ldinc_starting_equipment.fn.get_default()

	if not ldinc_starting_equipment.fn.settings_ignore_others() and #ldinc_starting_equipment.additional > 0 then
		if not ldinc_starting_equipment.fn.settings_append_default_to_others() then
			items = {}
		end

		for _, external in pairs(ldinc_starting_equipment.additional) do
			for _, item in ipairs(external) do
				table.insert(items, item)
			end
		end
	end


	for _, item in ipairs(items) do
		if not item then
			goto continue
		end

		local success, err = pcall(function()
			player.insert(item)
		end)

		if not success then
			local err_string = "invalid item key"

			if type(err) == "string" then
				err_string = err
			end

			log("Invalid item '" .. item.name .. "' was ignored to add as starting equipment with error: " .. err_string)
		end

		::continue::
	end
end
