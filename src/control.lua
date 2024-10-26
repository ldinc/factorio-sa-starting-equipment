local equipment = require('lib.script.equipment')

local function on_cutscene_cancelled(player_id)
	local player = game.get_player(player_id)

	if player then
		equipment.check_starting_equipment(game.get_player(player_id))
	end
end

script.on_event(
	defines.events.on_cutscene_cancelled,
	function(event)
		on_cutscene_cancelled(event.player_index)
	end
)

script.on_event(
	defines.events.on_cutscene_finished,
	function (event)
		-- using same handler
		on_cutscene_cancelled(event.player_index)
	end
)
