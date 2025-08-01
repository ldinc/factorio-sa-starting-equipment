require('lib.script.items')
require('lib.script.settings')

function ldinc_starting_equipment.fn.on_init()
	if not storage.ldinc then storage.ldinc = {} end

	if not storage.ldinc.starting_equipment then storage.ldinc.starting_equipment = {} end
	if not storage.ldinc.starting_equipment.has then storage.ldinc.starting_equipment.has = {} end
end

function ldinc_starting_equipment.fn.on_load()
	-- ldinc_starting_equipment.fn.on_init()
end

function ldinc_starting_equipment.fn.on_update()
	ldinc_starting_equipment.fn.on_init()
end

---@param player_index integer
function ldinc_starting_equipment.fn.on_player_removed(player_index)
	storage.ldinc.starting_equipment.has[player_index] = false
end

---@param player_index integer
function ldinc_starting_equipment.fn.on_player_removed_has_equipment(player_index)
	storage.ldinc.starting_equipment.has[player_index] = true
end

---@param player LuaPlayer
function ldinc_starting_equipment.fn.check_starting_equipment(player)
	local state = storage.ldinc.starting_equipment.has[player.index]

	if state == true then
		return
	end

	local items = ldinc_starting_equipment.fn.get_default()
	local additional_len = 0

	for _ in pairs(ldinc_starting_equipment.additional) do
		additional_len = additional_len + 1
	end

	if not ldinc_starting_equipment.fn.settings_ignore_others() and additional_len > 0 then
		if not ldinc_starting_equipment.fn.settings_append_default_to_others() then
			log("no default")
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

	ldinc_starting_equipment.fn.on_player_removed_has_equipment(player.index)
end
