-- luacheck config for a Factorio 2.x mod (https://luacheck.readthedocs.io)
-- Run: docker compose run --rm lint   |   .\run-tests.ps1 -LintOnly   |   CI "lint" job

std = "lua52"             -- Factorio runs a modified Lua 5.2
max_line_length = 150
codes = true
exclude_files = { ".factorio-test-data/**", "docker/**" }

-- Factorio globals shared by all stages
read_globals = {
	"log",
	"localised_print",
	"serpent",
	"table_size",
	"bit32",
	"mods",
	"helpers",
	table = { fields = { "deepcopy", "compare" } },
	string = { fields = { "split" } },
}

-- This mod's own namespace (created in control.lua / lib files)
globals = {
	"ldinc_starting_equipment",
}

-- ---------------------------------------------------------------- runtime stage (control)
local runtime = {
	read_globals = {
		"game",
		"script",
		"defines",
		"prototypes",
		"remote",
		"commands",
		"rendering",
		"rcon",
		-- settings.global[name] = { value = ... } is allowed at runtime
		settings = { fields = {
			global = { read_only = false, other_fields = true },
			startup = { other_fields = true },
			player = { other_fields = true },
			get_player_settings = {},
		} },
	},
	globals = {
		"storage",
	},
}

files["src/control.lua"] = runtime
files["src/lib/**/*.lua"] = runtime

-- ---------------------------------------------------------------- settings / data stage
files["src/settings*.lua"] = {
	read_globals = { settings = { other_fields = true } },
	globals = { "data" },
}
files["src/data*.lua"] = {
	read_globals = { "settings", "defines" },
	globals = { "data" },
}

-- ---------------------------------------------------------------- FactorioTest suites
files["src/tests/**/*.lua"] = {
	read_globals = {
		"game",
		"script",
		"defines",
		"prototypes",
		"remote",
		"rendering",
		settings = { fields = { global = { read_only = false, other_fields = true } } },
		-- FactorioTest
		"describe", "test", "it",
		"before_all", "after_all", "before_each", "after_each", "after_test",
		"async", "done", "on_tick", "after_ticks", "ticks_between_tests", "tags",
		-- luassert (load_luassert = true): assert.are.same(...), assert.is_nil(...), ...
		assert = { other_fields = true },
	},
	globals = {
		"storage",
	},
}
