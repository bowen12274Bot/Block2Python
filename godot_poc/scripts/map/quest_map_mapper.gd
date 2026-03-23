extends RefCounted
class_name QuestMapMapper


static func empty_map_view(message: String) -> Dictionary:
	return {
		"quest_title": "Quest Map",
		"mode_label": "Mode: -",
		"current_node_label": "Current Node: -",
		"summary": message,
		"group_summary": "0 groups visible | 0 active | 0 completed | 0 enterable",
		"groups": [],
		"show_legacy_nodes": false,
		"nodes": [],
	}


static func map_game_state(state: Dictionary) -> Dictionary:
	var current_node_title: String = str(state.get("node_title", str(state.get("node_id", ""))))
	var mode_value: String = str(state.get("mode", ""))
	var map_route_variant: Variant = state.get("map_route", {})
	var map_route: Dictionary = map_route_variant if map_route_variant is Dictionary else {}

	var group_views: Array[Dictionary] = _build_group_views(map_route)
	var summary: String = "Main map synced from live route state."
	if group_views.is_empty():
		summary = "Main map is waiting for route data from bridge state."

	return {
		"quest_title": _quest_title_from_route(map_route),
		"mode_label": "Mode: %s" % mode_value,
		"current_node_label": "Current Node: %s" % current_node_title,
		"summary": summary,
		"group_summary": _build_group_summary(group_views),
		"groups": group_views,
		"show_legacy_nodes": false,
		"nodes": [],
	}


static func _quest_title_from_route(map_route: Dictionary) -> String:
	var title: String = str(map_route.get("title", ""))
	if title != "":
		return title
	return "Quest Map"


static func _build_group_views(map_route: Dictionary) -> Array[Dictionary]:
	var groups_variant: Variant = map_route.get("groups", [])
	if not (groups_variant is Array):
		return []

	var group_views: Array[Dictionary] = []
	for group_variant in groups_variant:
		if group_variant is Dictionary:
			group_views.append(_build_group_view(group_variant))
	return group_views


static func _build_group_view(group: Dictionary) -> Dictionary:
	var group_id: String = str(group.get("group_id", ""))
	var title: String = str(group.get("title", "Group"))
	var status_key: String = str(group.get("status_key", "locked"))
	var demo_route_steps: Array[Dictionary] = _step_dict_array(group.get("demo_route", []))
	var practice_route_steps: Array[Dictionary] = _step_dict_array(group.get("practice_route", []))
	var demo_slot: Dictionary = _normalized_slot_view(group.get("demo_slot", {}), "demo", "Demo")
	var practice_slot: Dictionary = _normalized_slot_view(group.get("practice_slot", {}), "practice", "Practice")
	var story_step: Dictionary = _first_step_by_type(demo_route_steps, "story")

	return {
		"group_id": group_id,
		"title": title,
		"subtitle": "Demo + Practice",
		"theme_title": _theme_title_for_group(group_id, title),
		"theme_description": _theme_description_for_group(group_id),
		"unlock_blocks": _unlock_blocks_for_group(group_id),
		"status_key": status_key,
		"status_label": str(group.get("status_label", _status_label(status_key))),
		"is_enterable": bool(group.get("is_enterable", status_key != "locked")),
		"progress_label": _group_progress_label(demo_slot, practice_slot),
		"current_label": str(group.get("current_label", "")),
		"node_titles": _tracked_titles(demo_route_steps, practice_route_steps),
		"node_views": [],
		"demo_route_summary": _build_route_summary(demo_route_steps),
		"demo_route_step_titles": _route_step_titles(demo_route_steps),
		"demo_route_steps": demo_route_steps,
		"story_step": story_step,
		"practice_route_summary": _build_route_summary(practice_route_steps),
		"practice_route_step_titles": _route_step_titles(practice_route_steps),
		"practice_route_steps": practice_route_steps,
		"demo_slot": demo_slot,
		"practice_slot": practice_slot,
	}


static func _normalized_slot_view(slot_variant: Variant, slot_key: String, title: String) -> Dictionary:
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
	return {
		"slot_key": slot_key,
		"title": str(slot.get("title", title)),
		"status_key": str(slot.get("status_key", "locked")),
		"status_label": str(slot.get("status_label", _status_label(str(slot.get("status_key", "locked"))))),
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


static func _theme_title_for_group(group_id: String, fallback_title: String) -> String:
	match group_id:
		"group-01":
			return "Stage 01: Basic IO"
		_:
			return fallback_title


static func _theme_description_for_group(group_id: String) -> String:
	match group_id:
		"group-01":
			return "Learn the new IO blocks in Demo, then unlock a 5-stage Practice bundle."
		_:
			return "This stage will unlock new blocks and guided practice in a later update."


static func _unlock_blocks_for_group(group_id: String) -> Array[Dictionary]:
	match group_id:
		"group-01":
			return [
				{"title": "print", "description": "Output text to the screen."},
				{"title": "input", "description": "Read user input into your program."},
			]
		_:
			return [
				{"title": "Coming Soon", "description": "Future stages will add more blocks here."},
			]


static func _build_route_summary(route_steps: Array[Dictionary]) -> String:
	var step_titles: PackedStringArray = []
	for route_step in route_steps:
		step_titles.append(str(route_step.get("title", "Step")))
	return " -> ".join(step_titles)


static func _route_step_titles(route_steps: Array[Dictionary]) -> Array[String]:
	var titles: Array[String] = []
	for route_step in route_steps:
		titles.append(str(route_step.get("title", "")))
	return titles


static func _group_progress_label(demo_slot: Dictionary, practice_slot: Dictionary) -> String:
	var demo_seen := "Seen" if bool(demo_slot.get("viewed", false)) else "Unseen"
	var practice_total: int = int(practice_slot.get("total_count", 0))
	var practice_completed: int = int(practice_slot.get("completed_count", 0))
	if not bool(practice_slot.get("is_unlocked", false)):
		return "Demo: %s | Practice: Locked" % demo_seen
	return "Demo: %s | Practice: %d / %d" % [demo_seen, practice_completed, max(practice_total, 1)]


static func _tracked_titles(demo_route_steps: Array[Dictionary], practice_route_steps: Array[Dictionary]) -> Array[String]:
	var results: Array[String] = []
	var seen: Dictionary = {}
	for step in demo_route_steps:
		_append_unique_title(results, seen, step)
	for step in practice_route_steps:
		_append_unique_title(results, seen, step)
	return results


static func _append_unique_title(results: Array[String], seen: Dictionary, step: Dictionary) -> void:
	if not _is_trackable_step(step):
		return
	var title: String = str(step.get("title", ""))
	if title == "" or seen.has(title):
		return
	seen[title] = true
	results.append(title)


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
			"status_label": _status_label(status_key),
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


static func _first_step_by_type(route_steps: Array[Dictionary], step_type: String) -> Dictionary:
	for step in route_steps:
		if str(step.get("step_type", "")) == step_type:
			return step
	return {}


static func _build_group_summary(group_views: Array[Dictionary]) -> String:
	var completed_groups := 0
	var current_groups := 0
	var available_groups := 0
	for group_view in group_views:
		var status_key: String = str(group_view.get("status_key", "locked"))
		if status_key == "completed":
			completed_groups += 1
		elif status_key == "current":
			current_groups += 1
		if status_key != "locked":
			available_groups += 1
	return "%d groups visible | %d active | %d completed | %d enterable" % [group_views.size(), current_groups, completed_groups, available_groups]


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


static func _is_trackable_step(step: Dictionary) -> bool:
	if not _string_array(step.get("tracked_node_ids", [])).is_empty():
		return true
	if not _string_array(step.get("level_ids", [])).is_empty():
		return true
	return _has_non_empty_string(step.get("node_id", null)) or _has_non_empty_string(step.get("challenge_id", null)) or _has_non_empty_string(step.get("scene_id", null))


static func _has_non_empty_string(value: Variant) -> bool:
	return value is String and str(value) != ""


static func _status_label(status_key: String) -> String:
	match status_key:
		"current":
			return "Current"
		"completed":
			return "Completed"
		"available":
			return "Available"
		"reviewing":
			return "Reviewing"
		_:
			return "Locked"
