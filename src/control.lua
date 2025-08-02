if ldinc_starting_equipment == nil then ldinc_starting_equipment = {} end
if ldinc_starting_equipment.fn == nil then ldinc_starting_equipment.fn = {} end
if ldinc_starting_equipment.additional == nil then ldinc_starting_equipment.additional = {} end

require('lib.script.equipment')
require('lib.script.items')
require('lib.script.settings')

script.on_init(
	ldinc_starting_equipment.fn.on_init
)

script.on_load(
	ldinc_starting_equipment.fn.on_load
)

script.on_configuration_changed(
	ldinc_starting_equipment.fn.on_update
)

script.on_event(
	defines.events.on_player_joined_game,
	function (event)
		ldinc_starting_equipment.fn.add_to_queue(event.player_index)
	end
)

script.on_event(
	defines.events.on_player_removed,
	function(event)
		ldinc_starting_equipment.fn.on_player_removed(event.player_index)
	end
)

-- script.on_event(
-- 	defines.events.on_cutscene_cancelled,
-- 	function(event)
-- 		-- handle_player(event.player_index)
-- 		ldinc_starting_equipment.fn.add_to_queue(event.player_index)
-- 	end
-- )

-- script.on_event(
-- 	defines.events.on_cutscene_finished,
-- 	function(event)
-- 		handle_player(event.player_index)
-- 	end
-- )

script.on_event(
	defines.events.on_player_created,
	function(event)
		-- handle_player(event.player_index)
		ldinc_starting_equipment.fn.add_to_queue(event.player_index)
	end
)

script.on_nth_tick(
	120,
	ldinc_starting_equipment.fn.game_tick
)

remote.add_interface("ldinc_starting_equipment", {
	add_list = ldinc_starting_equipment.fn.external_add_items,
	add_by_string = ldinc_starting_equipment.fn.external_add_items_by_string,
})
