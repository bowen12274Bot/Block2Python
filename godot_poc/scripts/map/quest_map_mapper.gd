extends RefCounted
class_name QuestMapMapper

const QuestMapRulesScript = preload("res://scripts/map/quest_map_rules.gd")


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
	var current_node_id: String = str(state.get("node_id", ""))
	var current_node_title: String = str(state.get("node_title", current_node_id))
	var mode_value: String = str(state.get("mode", ""))
	var progress_state: Dictionary = {}
	var progress_variant: Variant = state.get("progress", {})
	if progress_variant is Dictionary:
		progress_state = progress_variant
	var map_route_variant: Variant = state.get("map_route", {})
	var map_route: Dictionary = {}
	if map_route_variant is Dictionary:
		map_route = map_route_variant

	var group_views: Array[Dictionary] = _build_group_views(map_route, progress_state)
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


static func _build_group_views(map_route: Dictionary, progress_state: Dictionary) -> Array[Dictionary]:
	var groups_variant: Variant = map_route.get("groups", [])
	if not (groups_variant is Array):
		return []

	var raw_groups: Array[Dictionary] = []
	for group_variant in groups_variant:
		if group_variant is Dictionary:
			raw_groups.append(group_variant)

	var group_views: Array[Dictionary] = []
	for index in raw_groups.size():
		var group: Dictionary = raw_groups[index]
		group_views.append(_build_group_view(group, index, group_views, progress_state))
	return group_views


static func _build_group_view(group: Dictionary, _group_index: int, _prior_group_views: Array[Dictionary], progress_state: Dictionary) -> Dictionary:
	var demo_route_steps: Array[Dictionary] = _step_dict_array(group.get("demo_route", []))
	var practice_route_steps: Array[Dictionary] = _step_dict_array(group.get("practice_route", []))
	var all_steps: Array[Dictionary] = []
	all_steps.append_array(demo_route_steps)
	all_steps.append_array(practice_route_steps)

	var progress := QuestMapRulesScript.group_progress(all_steps)
	var group_id: String = str(group.get("group_id", ""))
	var title: String = str(group.get("title", "Group"))
	var status_key: String = str(group.get("status_key", "locked"))
	var status_label: String = str(group.get("status_label", QuestMapRulesScript.status_label(status_key)))
	var current_label: String = str(group.get("current_label", ""))
	var demo_slot: Dictionary = _slot_dict(group.get("demo_slot", {}))
	var practice_slot: Dictionary = _slot_dict(group.get("practice_slot", {}))
	if demo_slot.is_empty():
		demo_slot = _build_slot_view("demo", "Demo", demo_route_steps, progress_state, group_id)
	if practice_slot.is_empty():
		practice_slot = _build_slot_view("practice", "Practice", practice_route_steps, progress_state, group_id)

	return {
		"group_id": group_id,
		"title": title,
		"subtitle": "Demo + Practice",
		"theme_title": _theme_title_for_group(group_id, title),
		"theme_description": _theme_description_for_group(group_id),
		"unlock_blocks": _unlock_blocks_for_group(group_id),
		"status_key": status_key,
		"status_label": status_label,
		"is_enterable": bool(group.get("is_enterable", status_key != "locked")),
		"progress_label": "Progress: %d / %d tracked steps" % [progress["completed"], progress["total"]],
		"current_label": current_label,
		"node_titles": QuestMapRulesScript.tracked_titles(demo_route_steps, practice_route_steps),
		"node_views": [],
		"demo_route_summary": _build_route_summary(demo_route_steps),
		"demo_route_step_titles": _route_step_titles(demo_route_steps),
		"demo_route_steps": demo_route_steps,
		"practice_route_summary": _build_route_summary(practice_route_steps),
		"practice_route_step_titles": _route_step_titles(practice_route_steps),
		"practice_route_steps": practice_route_steps,
		"demo_slot": demo_slot,
		"practice_slot": practice_slot,
	}


static func _build_slot_view(slot_key: String, title: String, route_steps: Array[Dictionary], progress_state: Dictionary, group_id: String) -> Dictionary:
	var slot_status_key: String = QuestMapRulesScript.slot_status_key(route_steps)
	var primary_step: Dictionary = QuestMapRulesScript.primary_slot_step(route_steps)
	var cleared_level_ids: Array[String] = _string_array(progress_state.get("cleared_level_ids", []))
	var slot_progress: Dictionary = QuestMapRulesScript.slot_progress(route_steps, cleared_level_ids)
	var practice_levels: Array[Dictionary] = []
	var demo_seen_group_ids: Array[String] = _string_array(progress_state.get("demo_seen_group_ids", []))
	var demo_viewed: bool = group_id in demo_seen_group_ids
	var is_unlocked: bool = slot_status_key != "locked"
	var completed_count: int = int(slot_progress.get("completed", 0))
	var total_count: int = int(slot_progress.get("total", 0))
	var next_level_id: String = ""
	var entry_level_id: String = ""
	if slot_key == "practice":
		practice_levels = QuestMapRulesScript.practice_levels(route_steps, cleared_level_ids)
		is_unlocked = demo_viewed and not primary_step.is_empty()
		next_level_id = _first_uncleared_level_id(primary_step, cleared_level_ids)
		entry_level_id = next_level_id if next_level_id != "" else _first_level_id(primary_step)
		completed_count = _completed_level_count(primary_step, cleared_level_ids)
		total_count = _level_count(primary_step)
	else:
		is_unlocked = true

	return {
		"slot_key": slot_key,
		"title": title,
		"status_key": slot_status_key,
		"status_label": QuestMapRulesScript.status_label(slot_status_key),
		"summary": _build_route_summary(route_steps),
		"progress_label": "%d / %d" % [slot_progress["completed"], slot_progress["total"]],
		"is_unlocked": is_unlocked,
		"viewed": demo_viewed if slot_key == "demo" else false,
		"completed_count": completed_count,
		"total_count": total_count,
		"next_level_id": next_level_id,
		"entry_level_id": entry_level_id,
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


static func _first_uncleared_level_id(primary_step: Dictionary, cleared_level_ids: Array[String]) -> String:
	for level_id in _string_array(primary_step.get("level_ids", [])):
		if level_id not in cleared_level_ids:
			return level_id
	return ""


static func _first_level_id(primary_step: Dictionary) -> String:
	var level_ids: Array[String] = _string_array(primary_step.get("level_ids", []))
	if level_ids.is_empty():
		return ""
	return level_ids[0]


static func _completed_level_count(primary_step: Dictionary, cleared_level_ids: Array[String]) -> int:
	var completed := 0
	for level_id in _string_array(primary_step.get("level_ids", [])):
		if level_id in cleared_level_ids:
			completed += 1
	return completed


static func _level_count(primary_step: Dictionary) -> int:
	return _string_array(primary_step.get("level_ids", [])).size()


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


static func _string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item in value:
			result.append(str(item))
	return result
