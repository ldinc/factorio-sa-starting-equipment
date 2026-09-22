-- Parsing of the "item=count quality::item=count" settings string and item normalization.
local h = require("tests/helpers")
local fn = ldinc_starting_equipment.fn

describe("get_items_from_string", function()
	test("empty string gives an empty list", function()
		assert.are.same({}, fn.get_items_from_string(""))
	end)

	test("plain entries", function()
		assert.are.same({
			{ name = "iron-plate", count = 5 },
			{ name = "coal",       count = 10 },
		}, fn.get_items_from_string("iron-plate=5 coal=10"))
	end)

	test("names with underscores and digits are kept whole", function()
		assert.are.same({
			{ name = "my_mod_item",   count = 2 },
			{ name = "5d-item_mk2",   count = 1 },
		}, fn.get_items_from_string("my_mod_item=2 5d-item_mk2=1"))
	end)

	test("quality prefix", function()
		assert.are.same({
			{ name = "se_core",    count = 1, quality = "legendary" },
			{ name = "iron-plate", count = 3, quality = "normal" },
		}, fn.get_items_from_string("legendary::se_core=1 normal::iron-plate=3"))
	end)

	test("any whitespace separates entries", function()
		assert.are.same({
			{ name = "iron-plate", count = 1 },
			{ name = "coal",       count = 2 },
		}, fn.get_items_from_string("  iron-plate=1\t\ncoal=2  "))
	end)

	test("default setting value parses into 6 entries", function()
		local items = fn.get_items_from_string(h.DEFAULT_LIST)

		assert.are.equal(6, #items)
		assert.are.same({ name = "modular-armor", count = 1 }, items[1])
		assert.are.same({ name = "construction-robot", count = 10 }, items[6])
	end)

	test.each({
		"bad=5x",
		"foo=bar=3",
		"zero=0",
		"=5",
		"iron-plate",
		"iron-plate=-1",
		"::iron-plate=1",
		"epic::=1",
		"a::b::c=1",
	})("rejects '%s'", function(entry)
		assert.are.same({}, fn.get_items_from_string(entry))
	end)

	test("invalid entries do not affect valid ones", function()
		assert.are.same({
			{ name = "coal",       count = 1 },
			{ name = "iron-plate", count = 2 },
		}, fn.get_items_from_string("coal=1 bad=5x iron-plate=2"))
	end)
end)

describe("normalize_item", function()
	test("string becomes a stack of 1", function()
		assert.are.same({ name = "coal", count = 1 }, fn.normalize_item("coal"))
	end)

	test("table with a string name is returned as is", function()
		local item = { name = "coal", count = 5, quality = "normal" }

		assert.are.equal(item, fn.normalize_item(item))
	end)

	test.each({
		{ { count = 4 } },
		{ { name = 5 } },
		{ 42 },
		{ true },
	})("rejects %s", function(value)
		assert.is_nil(fn.normalize_item(value))
	end)

	test("rejects nil", function()
		assert.is_nil(fn.normalize_item(nil))
	end)
end)

describe("describe_item", function()
	test("never fails, whatever it gets", function()
		assert.are.equal("coal", fn.describe_item("coal"))
		assert.are.equal("coal", fn.describe_item({ name = "coal" }))
		assert.are.equal("<table without name>", fn.describe_item({ count = 1 }))
		assert.are.equal("42", fn.describe_item(42))
		assert.are.equal("nil", fn.describe_item(nil))
	end)
end)
