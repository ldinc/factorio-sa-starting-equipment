data:extend({
	{
		type          = "string-setting",
		name          = "freeplay_starting_equipment_list",
		setting_type  = "runtime-global",
		allow_blank   = true,
		default_value =
		'modular-armor=1 personal-roboport-equipment=1 battery-equipment=3 solar-panel-equipment=15 firearm-magazine=50 construction-robot=10',
		order         = 'aa_a',
	},
	{
		type          = "bool-setting",
		name          = "freeplay_starting_equipment_ignore_remote_calls",
		setting_type  = "runtime-global",
		allow_blank   = false,
		default_value = false,
		order         = 'aa_a',
	},
	{
		type          = "bool-setting",
		name          = "freeplay_starting_equipment_append_default_to_remote_calls",
		setting_type  = "runtime-global",
		allow_blank   = false,
		default_value = false,
		order         = 'aa_a',
	}
})
