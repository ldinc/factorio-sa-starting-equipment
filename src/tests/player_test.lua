-- Full flow with a real LuaPlayer. Headless runs have no players, so these tests are
-- tagged "needs-player": the Docker run skips them, `run-tests.ps1 -Graphics` runs them.
local h = require("tests/helpers")
local fn = ldinc_starting_equipment.fn

h.isolate()

tags("needs-player")
describe("with a real player", function()
	local player, inventory

	before_each(function()
		player = game.get_player(1)
		assert(player, "no player 1 in this run: use run-tests.ps1 -Graphics for these tests")

		inventory = player.get_main_inventory()
		assert(inventory, "player 1 has no main inventory")
		inventory.clear()

		storage.ldinc.starting_equipment.has[1] = nil
		storage.ldinc.starting_equipment.queue[1] = nil
		h.clear_additional()
		h.set_settings({ list = "iron-plate=7 coal=3", ignore = false, append = false })
	end)

	after_each(function()
		if inventory and inventory.valid then
			inventory.clear()
		end
	end)

	test("queued player receives the starting items", function()
		fn.add_to_queue(1)
		fn.game_tick()

		assert.are.equal(7, inventory.get_item_count("iron-plate"))
		assert.are.equal(3, inventory.get_item_count("coal"))
		assert.is_true(storage.ldinc.starting_equipment.has[1])
		assert.is_nil(storage.ldinc.starting_equipment.queue[1])
	end)

	test("items are given only once, even when queued again (rejoin)", function()
		fn.add_to_queue(1)
		fn.game_tick()
		fn.add_to_queue(1)
		fn.game_tick()

		assert.are.equal(7, inventory.get_item_count("iron-plate"))
		assert.is_nil(storage.ldinc.starting_equipment.queue[1])
	end)

	test("items registered by other mods are given", function()
		remote.call(h.INTERFACE, "add_by_string", "test_mod", "stone=4")

		fn.add_to_queue(1)
		fn.game_tick()

		assert.are.equal(4, inventory.get_item_count("stone"))
		assert.are.equal(0, inventory.get_item_count("iron-plate"))
	end)

	test("removed and re-created player gets the items again", function()
		fn.add_to_queue(1)
		fn.game_tick()
		inventory.clear()

		fn.on_player_removed(1)
		fn.add_to_queue(1)
		fn.game_tick()

		assert.are.equal(7, inventory.get_item_count("iron-plate"))
	end)
end)
