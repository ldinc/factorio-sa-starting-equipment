require('lib.script.items')
require('lib.script.settings')

function ldinc_starting_equipment.fn.on_init()
	if not storage.ldinc then storage.ldinc = {} end

	if not storage.ldinc.starting_equipment then storage.ldinc.starting_equipment = {} end
	if not storage.ldinc.starting_equipment.has then storage.ldinc.starting_equipment.has = {} end
	if not storage.ldinc.starting_equipment.queue then storage.ldinc.starting_equipment.queue = {} end
	if not storage.ldinc.starting_equipment.additional then storage.ldinc.starting_equipment.additional = {} end
end

function ldinc_starting_equipment.fn.on_load()
	-- ldinc_starting_equipment.fn.on_init()
end

function ldinc_starting_equipment.fn.on_update()
	ldinc_starting_equipment.fn.on_init()
end

---@param player_index integer
function ldinc_starting_equipment.fn.on_player_removed(player_index)
	storage.ldinc.starting_equipment.has[player_index] = nil
end

---@param player_index integer
function ldinc_starting_equipment.fn.equipment_was_added(player_index)
	storage.ldinc.starting_equipment.has[player_index] = true

	ldinc_starting_equipment.fn.remove_from_queue(player_index)
end

---@param player_index integer
function ldinc_starting_equipment.fn.add_to_queue(player_index)
	storage.ldinc.starting_equipment.queue[player_index] = false
end

---@param player_index integer
function ldinc_starting_equipment.fn.remove_from_queue(player_index)
	storage.ldinc.starting_equipment.queue[player_index] = nil
end

function ldinc_starting_equipment.fn.game_tick()
	if #storage.ldinc.starting_equipment.queue == 0 then
		return
	end

	for player_index, _ in pairs(storage.ldinc.starting_equipment.queue) do
		ldinc_starting_equipment.fn.check_starting_equipment(player_index)
	end
end

---@param player_index integer
function ldinc_starting_equipment.fn.check_starting_equipment(player_index)
	local state = storage.ldinc.starting_equipment.has[player_index]

	if state == true then
		return
	end

	local player = game.get_player(player_index)

	if player == nil then
		ldinc_starting_equipment.fn.remove_from_queue(player_index)

		return
	end

	local main_inventory = player.get_main_inventory()
	if main_inventory == nil then
		return
	end

	local items = ldinc_starting_equipment.fn.get_default()
	local additional_len = 0

	if not storage.ldinc.starting_equipment.additional then
		storage.ldinc.starting_equipment.additional = {}
	end

	for _ in pairs(storage.ldinc.starting_equipment.additional) do
		additional_len = additional_len + 1
	end

	if not ldinc_starting_equipment.fn.settings_ignore_others() and additional_len > 0 then
		if not ldinc_starting_equipment.fn.settings_append_default_to_others() then
			log("no default")
			items = {}
		end

		for _, external in pairs(storage.ldinc.starting_equipment.additional) do
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

	ldinc_starting_equipment.fn.equipment_was_added(player_index)
end
