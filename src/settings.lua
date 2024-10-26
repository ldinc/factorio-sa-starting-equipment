data:extend({
	{
		type          = "string-setting",
		name          = "freeplay_starting_equipment_list",
		setting_type  = "startup",
		allow_blank   = true,
		default_value = 'modular-armor=1 personal-roboport-equipment=1 battery-equipment=3 solar-panel-equipment=15 firearm-magazine=50 construction-robot=10',
		order         = 'aa_a',
	},
	{
		type          = "string-setting",
		name          = "freeplay_starting_equipment_drop_list",
		setting_type  = "startup",
		allow_blank   = true,
		default_value = 'burner-mining-drill=1 stone-furnace=1 wood=10',
		order         = 'aa_a',
	}
})