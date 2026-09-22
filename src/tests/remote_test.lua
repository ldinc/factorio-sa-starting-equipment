-- The remote interface other mods use: add_list and add_by_string.
local h = require("tests/helpers")

local function additional()
	return storage.ldinc.starting_equipment.additional
end

h.isolate()

before_each(function()
	h.clear_additional()
end)

test("interface is registered with both functions", function()
	local iface = remote.interfaces[h.INTERFACE]

	assert.is_not_nil(iface)
	assert.is_true(iface.add_list)
	assert.is_true(iface.add_by_string)
end)

describe("add_by_string", function()
	test("stores the parsed list", function()
		remote.call(h.INTERFACE, "add_by_string", "test_mod", "coal=2 epic::iron-plate=1")

		assert.are.same({
			{ name = "coal",       count = 2 },
			{ name = "iron-plate", count = 1, quality = "epic" },
		}, additional().test_mod)
	end)

	test("a second call replaces the first", function()
		remote.call(h.INTERFACE, "add_by_string", "test_mod", "coal=1")
		remote.call(h.INTERFACE, "add_by_string", "test_mod", "coal=9")

		assert.are.same({ { name = "coal", count = 9 } }, additional().test_mod)
	end)

	test("nil or empty string registers an empty list", function()
		remote.call(h.INTERFACE, "add_by_string", "empty_mod", "")
		remote.call(h.INTERFACE, "add_by_string", "nil_mod", nil)

		assert.are.same({}, additional().empty_mod)
		assert.are.same({}, additional().nil_mod)
	end)
end)

describe("add_list", function()
	test("stores the list", function()
		remote.call(h.INTERFACE, "add_list", "test_mod", { { name = "coal", count = 3 } })

		assert.are.same({ { name = "coal", count = 3 } }, additional().test_mod)
	end)

	test("a second call replaces the first", function()
		remote.call(h.INTERFACE, "add_list", "test_mod", { { name = "coal", count = 1 } })
		remote.call(h.INTERFACE, "add_list", "test_mod", { { name = "coal", count = 9 } })

		assert.are.same({ { name = "coal", count = 9 } }, additional().test_mod)
	end)

	test("strings become stacks of 1 and junk is dropped", function()
		remote.call(h.INTERFACE, "add_list", "test_mod", { "coal", { count = 4 }, 42, { name = "stone", count = 2 } })

		assert.are.same({
			{ name = "coal",  count = 1 },
			{ name = "stone", count = 2 },
		}, additional().test_mod)
	end)

	test("nil instead of a list does not raise", function()
		remote.call(h.INTERFACE, "add_list", "test_mod", nil)

		assert.are.same({}, additional().test_mod)
	end)
end)

test("lists from different mods are kept separately", function()
	remote.call(h.INTERFACE, "add_by_string", "mod_a", "coal=1")
	remote.call(h.INTERFACE, "add_list", "mod_b", { { name = "stone", count = 2 } })

	assert.are.same({ { name = "coal", count = 1 } }, additional().mod_a)
	assert.are.same({ { name = "stone", count = 2 } }, additional().mod_b)
end)

test("works before on_init ran (another mod calling from its own on_init)", function()
	storage.ldinc = nil

	remote.call(h.INTERFACE, "add_by_string", "early_mod", "coal=1")

	assert.are.same({ { name = "coal", count = 1 } }, storage.ldinc.starting_equipment.additional.early_mod)
	assert.are.same({}, storage.ldinc.starting_equipment.queue)
	assert.are.same({}, storage.ldinc.starting_equipment.has)
end)
