local equipment_script = {}

function equipment_script.check_starting_equipment(player)
	check_starting_equipment(player)
end

function check_starting_equipment(player)
	local success = player.insert { name = "wood", count = 1 } > 0

	if success then
		-- usualy for multiplayer game it works
		remove_starting_items(player)
		items_from_settings(player)
	else
		local inventory = player.get_inventory(defines.inventory.character_main)

		if inventory == nil then
			inventory = player.get_inventory(defines.inventory.god_main)
		end

		if inventory then
			remove_starting_items(inventory)
			items_from_settings(inventory)
		end
	end
end

function remove_starting_items(player)
	player.remove_item { name = "burner-mining-drill", count = 1 }
	player.remove_item { name = "stone-furnace", count = 5 }
	player.remove_item { name = "wood", count = 200 }
end

function items_from_settings(player)
	local input = settings.startup["freeplay_starting_equipment_list"].value

	if input ~= '' then

		for name, v in string.gmatch(input, "([%w%-]+)=(%d+)") do
			local count = tonumber(v)
			local success, result = pcall(function() player.insert { name = name, count = count } end)

			if success == false then
				log("freeplay_starting_equipment:: invalid item in settings for starting items: " ..
					name .. " count: " .. tostring(count) .. " error: " .. tostring(result))
			end
		end
	end
end

return equipment_script
