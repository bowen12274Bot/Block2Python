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
	var map_route_variant: Variant = state.get("map_route", {})
	var map_route: Dictionary = {}
	if map_route_variant is Dictionary:
		map_route = map_route_variant

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

	var raw_groups: Array[Dictionary] = []
	for group_variant in groups_variant:
		if group_variant is Dictionary:
			raw_groups.append(group_variant)

	var group_views: Array[Dictionary] = []
	for index in raw_groups.size():
		var group: Dictionary = raw_groups[index]
		group_views.append(_build_group_view(group, index, group_views))
	return group_views


static func _build_group_view(group: Dictionary, group_index: int, prior_group_views: Array[Dictionary]) -> Dictionary:
	var demo_route_steps: Array[Dictionary] = _step_dict_array(group.get("demo_route", []))
	var practice_route_steps: Array[Dictionary] = _step_dict_array(group.get("practice_route", []))
	var all_steps: Array[Dictionary] = []
	all_steps.append_array(demo_route_steps)
	all_steps.append_array(practice_route_steps)

	var intrinsic_status_key: String = QuestMapRulesScript.intrinsic_group_status_key(all_steps)
	var status_key: String = QuestMapRulesScript.group_status_key(group_index, intrinsic_status_key, prior_group_views)
	var current_label: String = QuestMapRulesScript.group_current_label(all_steps)
	var progress := QuestMapRulesScript.group_progress(all_steps)
	var demo_slot: Dictionary = _build_slot_view("demo", "Demo", demo_route_steps)
	var practice_slot: Dictionary = _build_slot_view("practice", "Practice", practice_route_steps)

	return {
		"group_id": str(group.get("group_id", "")),
		"title": str(group.get("title", "Group")),
		"subtitle": "Demo + Practice",
		"status_key": status_key,
		"status_label": QuestMapRulesScript.group_status_label(status_key, QuestMapRulesScript.is_planned_only_group(all_steps)),
		"is_enterable": status_key != "locked",
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


static func _build_slot_view(slot_key: String, title: String, route_steps: Array[Dictionary]) -> Dictionary:
	var slot_status_key: String = QuestMapRulesScript.slot_status_key(route_steps)
	var primary_step: Dictionary = QuestMapRulesScript.primary_slot_step(route_steps)
	var progress: Dictionary = QuestMapRulesScript.slot_progress(route_steps)
	var practice_levels: Array[Dictionary] = []
	if slot_key == "practice":
		practice_levels = QuestMapRulesScript.practice_levels(route_steps)

	return {
		"slot_key": slot_key,
		"title": title,
		"status_key": slot_status_key,
		"status_label": QuestMapRulesScript.status_label(slot_status_key),
		"summary": _build_route_summary(route_steps),
		"progress_label": "%d / %d" % [progress["completed"], progress["total"]],
		"primary_step": primary_step,
		"route_steps": route_steps,
		"practice_levels": practice_levels,
	}


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


