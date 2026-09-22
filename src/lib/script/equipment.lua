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
	local queue = storage.ldinc.starting_equipment.queue

	if next(queue) == nil then
		return
	end

	for player_index in pairs(queue) do
		ldinc_starting_equipment.fn.check_starting_equipment(player_index)
	end
end

---Collects the final list of starting items from the settings and the remote API.
---@return ItemStackDefinition[]
function ldinc_starting_equipment.fn.build_item_list()
	local items = ldinc_starting_equipment.fn.get_default()
	local additional = storage.ldinc.starting_equipment.additional or {}

	if ldinc_starting_equipment.fn.settings_ignore_others() or next(additional) == nil then
		return items
	end

	if not ldinc_starting_equipment.fn.settings_append_default_to_others() then
		items = {}
	end

	for _, external in pairs(additional) do
		for _, item in ipairs(external) do
			table.insert(items, item)
		end
	end

	return items
end

---@param target LuaPlayer|LuaEntity|LuaInventory
---@param items any[]
---@return integer inserted number of entries that were inserted (fully or partially)
function ldinc_starting_equipment.fn.give_items(target, items)
	local inserted = 0

	for _, raw_item in ipairs(items) do
		-- also covers lists stored by older versions without validation
		local item = ldinc_starting_equipment.fn.normalize_item(raw_item)

		if not item then
			log("Invalid starting equipment entry '" .. ldinc_starting_equipment.fn.describe_item(raw_item) .. "' was ignored")

			goto continue
		end

		if not prototypes.item[item.name] then
			log("Unknown item '" .. item.name .. "' was ignored as starting equipment")

			goto continue
		end

		if item.quality and not prototypes.quality[item.quality] then
			log("Unknown quality '" ..
				tostring(item.quality) .. "' for item '" .. item.name .. "' was ignored as starting equipment")

			goto continue
		end

		do
			local success, result = pcall(function()
				return target.insert(item)
			end)

			if not success then
				log("Item '" .. item.name .. "' was ignored as starting equipment with error: " .. tostring(result))

				goto continue
			end

			local wanted = item.count or 1

			if type(result) == "number" and result < wanted then
				log("Only " .. result .. " of " .. wanted .. " '" .. item.name .. "' fit into the inventory")
			end

			if type(result) == "number" and result > 0 then
				inserted = inserted + 1
			end
		end

		::continue::
	end

	return inserted
end

---@param player_index integer
function ldinc_starting_equipment.fn.check_starting_equipment(player_index)
	if storage.ldinc.starting_equipment.has[player_index] == true then
		ldinc_starting_equipment.fn.remove_from_queue(player_index)

		return
	end

	local player = game.get_player(player_index)

	if player == nil then
		ldinc_starting_equipment.fn.remove_from_queue(player_index)

		return
	end

	-- no inventory yet (cutscene, dead, waiting to respawn): try again on a later tick
	if player.get_main_inventory() == nil then
		return
	end

	ldinc_starting_equipment.fn.give_items(player, ldinc_starting_equipment.fn.build_item_list())
	ldinc_starting_equipment.fn.equipment_was_added(player_index)
end
