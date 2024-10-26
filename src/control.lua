local equipment = require('lib.script.equipment')

local function handle_player(player_id)
	local player = game.get_player(player_id)

	if player then
		equipment.check_starting_equipment(game.get_player(player_id))
	end
end

script.on_event(
	defines.events.on_cutscene_cancelled,
	function(event)
		handle_player(event.player_index)
	end
)

script.on_event(
	defines.events.on_cutscene_finished,
	function (event)
		handle_player(event.player_index)
	end
)


script.on_event(
	defines.events.on_player_created,
	function (event)
		handle_player(event.player_index)
	end
)