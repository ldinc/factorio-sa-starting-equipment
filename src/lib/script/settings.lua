if not ldinc_starting_equipment then ldinc_starting_equipment = {} end
if not ldinc_starting_equipment.fn then ldinc_starting_equipment.fn = {} end


---@return string
function ldinc_starting_equipment.fn.settings_equipment_list()
	return tostring(settings.global["freeplay_starting_equipment_list"].value)
end

---@return boolean
function ldinc_starting_equipment.fn.settings_ignore_others()
	local value =  settings.global["freeplay_starting_equipment_ignore_remote_calls"].value

	if type(value) == "boolean" then
		return value
	end

	return false
end

---@return boolean
function ldinc_starting_equipment.fn.settings_append_default_to_others()
	local value =  settings.global["freeplay_starting_equipment_append_default_to_remote_calls"].value

	if type(value) == "boolean" then
		return value
	end

	return false
end