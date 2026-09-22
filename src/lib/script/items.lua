if not ldinc_starting_equipment then ldinc_starting_equipment = {} end
if not ldinc_starting_equipment.fn then ldinc_starting_equipment.fn = {} end

require('lib.script.settings')

---@param str string
---@return ItemStackDefinition[]
function ldinc_starting_equipment.fn.get_items_from_string(str)
	if str == '' then
		return {}
	end

	local list = {}

	for entry in string.gmatch(str, "%S+") do
		-- anchored patterns: the whole entry must match, names may contain any char except ':' '=' and spaces
		local quality, name, count_str = string.match(entry, "^([^:=]+)::([^:=]+)=(%d+)$")

		if not quality then
			name, count_str = string.match(entry, "^([^:=]+)=(%d+)$")
		end

		if not name or not count_str then
			log("Starting equipment entry \"" .. entry .. "\" has invalid format, expected item=count or quality::item=count")

			goto continue
		end

		local count = tonumber(count_str)

		if not count or count < 1 then
			log("Starting equipment entry \"" .. entry .. "\" has invalid count")

			goto continue
		end

		local item = {
			name = name,
			count = count,
		}

		if quality then
			item.quality = quality
		end

		table.insert(list, item)

		::continue::
	end

	return list
end

---@return ItemStackDefinition[]
function ldinc_starting_equipment.fn.get_default()
	local items_string = ldinc_starting_equipment.fn.settings_equipment_list()

	return ldinc_starting_equipment.fn.get_items_from_string(items_string)
end

---@param item any
---@return ItemStackDefinition?
function ldinc_starting_equipment.fn.normalize_item(item)
	if type(item) == "string" then
		return { name = item, count = 1 }
	end

	if type(item) == "table" and type(item.name) == "string" then
		return item
	end

	return nil
end

---Safe text for any value, used in log messages.
---@param item any
---@return string
function ldinc_starting_equipment.fn.describe_item(item)
	if type(item) == "table" then
		return item.name ~= nil and tostring(item.name) or "<table without name>"
	end

	return tostring(item)
end

---@param mod_name string
---@param items any[]
---@return ItemStackDefinition[]
local function normalize_list(mod_name, items)
	local list = {}

	if type(items) ~= "table" then
		log("Mod '" .. tostring(mod_name) .. "' passed " .. type(items) .. " instead of a list of items, ignored")

		return list
	end

	for _, item in ipairs(items) do
		local normalized = ldinc_starting_equipment.fn.normalize_item(item)

		if normalized then
			table.insert(list, normalized)
		else
			log("Mod '" .. tostring(mod_name) .. "' passed invalid item '" ..
				ldinc_starting_equipment.fn.describe_item(item) .. "', ignored")
		end
	end

	return list
end

---@return table<string, ItemStackDefinition[]>
local function get_additional()
	-- remote calls may arrive before this mod's on_init (e.g. from another mod's on_init)
	ldinc_starting_equipment.fn.on_init()

	return storage.ldinc.starting_equipment.additional
end

---Registers (or replaces) the starting items provided by another mod.
---@param mod_name string
---@param items_string string
function ldinc_starting_equipment.fn.external_add_items_by_string(mod_name, items_string)
	get_additional()[mod_name] = ldinc_starting_equipment.fn.get_items_from_string(items_string or "")
end

---Registers (or replaces) the starting items provided by another mod.
---@param mod_name string
---@param items ItemStackDefinition[]
function ldinc_starting_equipment.fn.external_add_items(mod_name, items)
	get_additional()[mod_name] = normalize_list(mod_name, items)
end
