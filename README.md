Simple mod for setup starting equipment & items in freeplay game.

Settings format is list "item=count" separeted by space char ' '.

Example: `'modular-armor=1 personal-roboport-equipment=1 battery-equipment=3 solar-panel-equipment=15 firearm-magazine=50 construction-robot=10'`

Support multiplayer.

Remote interface for other mods integration:

```lua

--- Adding statrting items by array { {name=..., count=...} }
---@param mod_name string
---@param items SimpleItemStack[]
	ldinc_starting_equipment.add_list()

--- Adding statrting items by string "name=count another_name=another_count"
---@param mod_name string
---@param items_string string
	ldinc_starting_equipment.add_by_string()

```

Example:

```lua
function setup_starting_items()
	local default_starting_items = {
		{ name = "apm_equipment_burner_generator_basic", count = 1 },
		{ name = "burner-mining-drill",                  count = 12 },
		{ name = "apm_coke",                             count = 400 },
		{ name = "burner-inserter",                      count = 10 },
		{ name = "stone-furnace",                        count = 10 },
		{ name = "personal-roboport-equipment",          count = 1 },
		{ name = "battery-equipment",                    count = 2 },
		{ name = "apm_zx80_construction_robot",          count = 10 },
		{ name = "modular-armor",                        count = 1 },
		{ name = "apm_assembling_machine_0",             count = 5 },
		{ name = "firearm-magazine",                     count = 50 },
	}

	remote.call("ldinc_starting_equipment", "add_list", "apm_lib", default_starting_items)
end

```