if not ldinc_starting_equipment then ldinc_starting_equipment = {} end
if not ldinc_starting_equipment.fn then ldinc_starting_equipment.fn = {} end

require('lib.script.settings')

---@type data.EquipmentPrototype

---@param str string
---@return SimpleItemStack[]
function ldinc_starting_equipment.fn.get_items_from_string(str)
	if #str == 0 or str == '' then
		return {}
	end

	---@type SimpleItemStack[]
	local list = {}

	for name, v in string.gmatch(str, "([%w%-]+)=(%d+)") do
		local count = tonumber(v)

		---@type SimpleItemStack
		local item = {
			name = name,
			count = count,
		}

		table.insert(list, item)
	end

	return list
end

---@return SimpleItemStack[]
function ldinc_starting_equipment.fn.get_default()
	local items_string = ldinc_starting_equipment.fn.settings_equipment_list()

	return ldinc_starting_equipment.fn.get_items_from_string(items_string)
end

---@param mod_name string
---@param items_string string
function ldinc_starting_equipment.fn.external_add_items_by_string(mod_name, items_string)
	ldinc_starting_equipment.additional[mod_name] = ldinc_starting_equipment.fn.get_items_from_string(items_string)
end

---@param mod_name string
---@param items SimpleItemStack[]
function ldinc_starting_equipment.fn.external_add_items(mod_name, items)
	ldinc_starting_equipment.additional[mod_name] = items
end