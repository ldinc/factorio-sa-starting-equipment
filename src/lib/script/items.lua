if not ldinc_starting_equipment then ldinc_starting_equipment = {} end
if not ldinc_starting_equipment.fn then ldinc_starting_equipment.fn = {} end

require('lib.script.settings')

---@type data.EquipmentPrototype

---@param str string
---@return ItemStackDefinition[]
function ldinc_starting_equipment.fn.get_items_from_string(str)
	if #str == 0 or str == '' then
		return {}
	end

	local list = {}

	for entry in string.gmatch(str, "[^%s]+") do
		local quality, name, count_str

		quality, name, count_str = string.match(entry, "([%w%-]+)::([%w%-]+)=(%d+)")

		if not quality then
			name, count_str = string.match(entry, "([%w%-]+)=(%d+)")
		end

		if not name or not count_str then
			log("string \"" .. str .. "\" has invalid format")

			goto continue
		end

		local count = tonumber(count_str)

		if not count then
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

---@param mod_name string
---@param items_string string
function ldinc_starting_equipment.fn.external_add_items_by_string(mod_name, items_string)
	if storage.ldinc.starting_equipment.additional[mod_name] then
		storage.ldinc.starting_equipment.additional[mod_name] = ldinc_starting_equipment.fn.get_items_from_string(
			items_string)
	end
end

---@param mod_name string
---@param items ItemStackDefinition[]
function ldinc_starting_equipment.fn.external_add_items(mod_name, items)
	if not storage.ldinc.starting_equipment.additional[mod_name] then
		storage.ldinc.starting_equipment.additional[mod_name] = items
	end
end
