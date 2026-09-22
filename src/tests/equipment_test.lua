-- Item list building, item insertion and the join queue. Runs headless (no player needed).
local h = require("tests/helpers")
local fn = ldinc_starting_equipment.fn

h.isolate()

describe("build_item_list", function()
	before_each(function()
		h.clear_additional()
		h.set_settings({ list = "iron-plate=5", ignore = false, append = false })
	end)

	test("uses the setting when no other mod registered items", function()
		assert.are.same({ { name = "iron-plate", count = 5 } }, fn.build_item_list())
	end)

	test("empty setting and no other mods gives nothing", function()
		h.set_settings({ list = "" })

		assert.are.same({}, fn.build_item_list())
	end)

	test("other mods' items replace the setting by default", function()
		fn.external_add_items_by_string("test_mod", "coal=2")

		assert.are.same({ { name = "coal", count = 2 } }, fn.build_item_list())
	end)

	test("append setting keeps the setting items and adds the others", function()
		h.set_settings({ append = true })
		fn.external_add_items_by_string("test_mod", "coal=2")

		assert.are.same({
			{ name = "iron-plate", count = 5 },
			{ name = "coal",       count = 2 },
		}, fn.build_item_list())
	end)

	test("ignore setting uses only the setting items", function()
		h.set_settings({ ignore = true })
		fn.external_add_items_by_string("test_mod", "coal=2")

		assert.are.same({ { name = "iron-plate", count = 5 } }, fn.build_item_list())
	end)

	test("building the list does not change the stored lists", function()
		h.set_settings({ append = true })
		fn.external_add_items_by_string("test_mod", "coal=2")

		fn.build_item_list()
		fn.build_item_list()

		assert.are.same({ { name = "coal", count = 2 } }, storage.ldinc.starting_equipment.additional.test_mod)
		assert.are.equal(2, #fn.build_item_list())
	end)
end)

describe("give_items", function()
	local inv

	before_each(function()
		inv = game.create_inventory(10)
	end)

	after_each(function()
		if inv and inv.valid then
			inv.destroy()
		end
	end)

	test("inserts valid items, strings count as 1", function()
		local inserted = fn.give_items(inv, { { name = "iron-plate", count = 5 }, "coal" })

		assert.are.equal(2, inserted)
		assert.are.equal(5, inv.get_item_count("iron-plate"))
		assert.are.equal(1, inv.get_item_count("coal"))
	end)

	test("skips unknown item names without raising", function()
		local inserted = fn.give_items(inv, { { name = "no-such-item", count = 1 }, { name = "iron-plate", count = 1 } })

		assert.are.equal(1, inserted)
		assert.are.equal(1, inv.get_item_count("iron-plate"))
	end)

	test("skips unknown quality without raising", function()
		local inserted = fn.give_items(inv, { { name = "iron-plate", count = 1, quality = "no-such-quality" } })

		assert.are.equal(0, inserted)
		assert.is_true(inv.is_empty())
	end)

	test("accepts the normal quality", function()
		local inserted = fn.give_items(inv, { { name = "iron-plate", count = 3, quality = "normal" } })

		assert.are.equal(1, inserted)
		assert.are.equal(3, inv.get_item_count("iron-plate"))
	end)

	test("skips junk entries without raising", function()
		local inserted = fn.give_items(inv, { 42, { count = 4 }, "iron-plate" })

		assert.are.equal(1, inserted)
		assert.are.equal(1, inv.get_item_count("iron-plate"))
	end)

	test("full inventory does not raise, keeps what fits", function()
		local small = game.create_inventory(1)
		local stack_size = prototypes.item["iron-plate"].stack_size

		local inserted = fn.give_items(small, {
			{ name = "iron-plate", count = stack_size * 5 },
			{ name = "coal",       count = 1 },
		})

		assert.are.equal(1, inserted)
		assert.are.equal(stack_size, small.get_item_count("iron-plate"))
		assert.are.equal(0, small.get_item_count("coal"))

		small.destroy()
	end)

	test("every item in the default setting exists in this game version", function()
		local items = fn.get_items_from_string(h.DEFAULT_LIST)

		assert.are.equal(#items, fn.give_items(inv, items))

		for _, item in ipairs(items) do
			assert.are.equal(item.count, inv.get_item_count(item.name), item.name)
		end
	end)
end)

describe("join queue", function()
	local queue, has

	before_each(function()
		queue = storage.ldinc.starting_equipment.queue
		has = storage.ldinc.starting_equipment.has

		for k in pairs(queue) do queue[k] = nil end
	end)

	test("game_tick with an empty queue does nothing", function()
		fn.game_tick()

		assert.are.same({}, queue)
	end)

	-- Regression test for the old `#queue == 0` check: a queue keyed by player index
	-- is sparse, so `#` could report 0 and the queue was never processed.
	test("sparse queue is processed (non-existent players are dropped)", function()
		queue[4242] = false
		queue[7] = false

		fn.game_tick()

		assert.is_nil(queue[4242])
		assert.is_nil(queue[7])
	end)

	test("player who already got the kit is dropped from the queue", function()
		has[4242] = true
		fn.add_to_queue(4242)

		fn.game_tick()

		assert.is_nil(queue[4242])
		assert.is_true(has[4242])
	end)

	test("equipment_was_added marks the player and removes them from the queue", function()
		fn.add_to_queue(4242)

		fn.equipment_was_added(4242)

		assert.is_true(has[4242])
		assert.is_nil(queue[4242])
	end)

	test("on_player_removed forgets the player", function()
		has[4242] = true

		fn.on_player_removed(4242)

		assert.is_nil(has[4242])
	end)
end)
