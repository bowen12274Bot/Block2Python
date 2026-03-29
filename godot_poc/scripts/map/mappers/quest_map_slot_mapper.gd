extends RefCounted
class_name QuestMapSlotMapper

const StatusLabelHelperScript = preload("res://scripts/shared/status_label_helper.gd")


static func map_slot(slot_variant: Variant, slot_key: String, title: String) -> Dictionary:
	var slot: Dictionary = _slot_dict(slot_variant)
	var route_steps: Array[Dictionary] = _step_dict_array(slot.get("route_steps", []))
	var primary_step: Dictionary = _slot_dict(slot.get("primary_step", {}))
	if primary_step.is_empty():
		primary_step = _primary_step(route_steps)
	var completed_count: int = int(slot.get("completed_count", 0))
	var total_count: int = int(slot.get("total_count", 0))
	var practice_levels: Array[Dictionary] = []
	if slot_key == "practice":
		practice_levels = _practice_levels_from_slot(slot, primary_step)
	var progress_label: String = str(slot.get("progress_label", ""))
	if progress_label == "":
		progress_label = "%d / %d" % [completed_count, max(total_count, 1)]
	var status_key: String = str(slot.get("status_key", "locked"))
	return {
		"slot_key": slot_key,
		"title": str(slot.get("title", title)),
		"status_key": status_key,
		"status_label": StatusLabelHelperScript.label_for_status(status_key),
		"summary": str(slot.get("summary", _build_route_summary(route_steps))),
		"progress_label": progress_label,
		"is_unlocked": bool(slot.get("is_unlocked", slot_key != "practice")),
		"viewed": bool(slot.get("viewed", false)),
		"completed_count": completed_count,
		"total_count": total_count,
		"next_level_id": str(slot.get("next_level_id", "")),
		"entry_level_id": str(slot.get("entry_level_id", "")),
		"primary_step": primary_step,
		"route_steps": route_steps,
		"practice_levels": practice_levels,
	}


static func step_dict_array(value: Variant) -> Array[Dictionary]:
	return _step_dict_array(value)


static func first_step_by_type(route_steps: Array[Dictionary], step_type: String) -> Dictionary:
	for step in route_steps:
		if str(step.get("step_type", "")) == step_type:
			return step
	return {}


static func _build_route_summary(route_steps: Array[Dictionary]) -> String:
	var step_titles: PackedStringArray = []
	for route_step in route_steps:
		step_titles.append(str(route_step.get("title", "Step")))
	return " -> ".join(step_titles)


static func _practice_levels_from_slot(slot: Dictionary, primary_step: Dictionary) -> Array[Dictionary]:
	var level_ids: Array[String] = _string_array(primary_step.get("level_ids", []))
	if level_ids.is_empty():
		return []
	var completed_count: int = int(slot.get("completed_count", 0))
	var results: Array[Dictionary] = []
	for index in level_ids.size():
		var status_key := "locked"
		if index < completed_count:
			status_key = "completed"
		elif index == completed_count and bool(slot.get("is_unlocked", false)):
			status_key = "available"
		results.append({
			"level_id": level_ids[index],
			"title": "Practice %02d" % [index + 1],
			"status_key": status_key,
			"status_label": StatusLabelHelperScript.label_for_status(status_key),
		})
	return results


static func _primary_step(route_steps: Array[Dictionary]) -> Dictionary:
	for step in route_steps:
		if str(step.get("status_key", "")) == "current":
			return step
	for step in route_steps:
		var status_key: String = str(step.get("status_key", ""))
		if status_key == "available" or status_key == "completed":
			return step
	return {}


static func _slot_dict(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value
	return {}


static func _step_dict_array(value: Variant) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	if value is Array:
		for item in value:
			if item is Dictionary:
				results.append(item)
	return results


static func _string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item in value:
			result.append(str(item))
	return result




