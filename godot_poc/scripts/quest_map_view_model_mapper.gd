extends RefCounted
class_name QuestMapViewModelMapper


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

	var intrinsic_status_key: String = _intrinsic_group_status_key(all_steps)
	var status_key: String = _group_status_key(group_index, intrinsic_status_key, prior_group_views)
	var current_label: String = _group_current_label(all_steps)
	var progress := _group_progress(all_steps)
	var demo_slot: Dictionary = _build_slot_view("demo", "Demo", demo_route_steps)
	var practice_slot: Dictionary = _build_slot_view("practice", "Practice", practice_route_steps)

	return {
		"group_id": str(group.get("group_id", "")),
		"title": str(group.get("title", "Group")),
		"subtitle": "Demo + Practice",
		"status_key": status_key,
		"status_label": _group_status_label(status_key, _is_planned_only_group(all_steps)),
		"is_enterable": status_key != "locked",
		"progress_label": "Progress: %d / %d tracked steps" % [progress["completed"], progress["total"]],
		"current_label": current_label,
		"node_titles": _tracked_titles(demo_route_steps, practice_route_steps),
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
	var slot_status_key: String = _slot_status_key(route_steps)
	var primary_step: Dictionary = _primary_slot_step(route_steps)
	var progress: Dictionary = _slot_progress(route_steps)
	var practice_levels: Array[Dictionary] = []
	if slot_key == "practice":
		practice_levels = _practice_levels(route_steps)

	return {
		"slot_key": slot_key,
		"title": title,
		"status_key": slot_status_key,
		"status_label": _status_label(slot_status_key),
		"summary": _build_route_summary(route_steps),
		"progress_label": "%d / %d" % [progress["completed"], progress["total"]],
		"primary_step": primary_step,
		"route_steps": route_steps,
		"practice_levels": practice_levels,
	}


static func _slot_status_key(route_steps: Array[Dictionary]) -> String:
	if _has_step_status(route_steps, "current"):
		return "current"
	if _all_trackable_steps_completed(route_steps):
		return "completed"
	if _has_step_status(route_steps, "available") or _has_step_status(route_steps, "completed"):
		return "available"
	return "locked"


static func _primary_slot_step(route_steps: Array[Dictionary]) -> Dictionary:
	for step in route_steps:
		if str(step.get("status_key", "")) == "current":
			return step
	for step in route_steps:
		var status_key: String = str(step.get("status_key", ""))
		if status_key == "available" or status_key == "completed":
			return step
	return {}


static func _slot_progress(route_steps: Array[Dictionary]) -> Dictionary:
	var tracked_steps: Array[Dictionary] = []
	for step in route_steps:
		if _is_trackable_step(step):
			tracked_steps.append(step)
	if tracked_steps.is_empty():
		return {"completed": 0, "total": 1}
	var primary_step: Dictionary = _primary_slot_step(route_steps)
	var level_ids: Array[String] = _string_array(primary_step.get("level_ids", []))
	if level_ids.size() > 1:
		var completed_levels := 0
		var level_views: Array[Dictionary] = _practice_levels(route_steps)
		for level_view in level_views:
			if str(level_view.get("status_key", "")) == "completed":
				completed_levels += 1
		return {"completed": completed_levels, "total": level_ids.size()}
	var completed := 0
	for step in tracked_steps:
		if str(step.get("status_key", "")) == "completed":
			completed += 1
	return {"completed": completed, "total": tracked_steps.size()}


static func _practice_levels(route_steps: Array[Dictionary]) -> Array[Dictionary]:
	var primary_step: Dictionary = _primary_slot_step(route_steps)
	var level_ids: Array[String] = _string_array(primary_step.get("level_ids", []))
	var step_status_key: String = str(primary_step.get("status_key", "locked"))
	var results: Array[Dictionary] = []
	for index in level_ids.size():
		var level_id: String = level_ids[index]
		var level_status_key: String = "locked"
		if step_status_key == "completed":
			level_status_key = "completed"
		elif step_status_key == "current" or step_status_key == "available":
			if index == 0:
				level_status_key = step_status_key
		results.append({
			"level_id": level_id,
			"title": "Practice %02d" % [index + 1],
			"status_key": level_status_key,
			"status_label": _status_label(level_status_key),
		})
	return results


static func _step_dict_array(value: Variant) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	if value is Array:
		for item in value:
			if item is Dictionary:
				results.append(item)
	return results


static func _intrinsic_group_status_key(all_steps: Array[Dictionary]) -> String:
	if _has_step_status(all_steps, "current"):
		return "current"
	if _all_trackable_steps_completed(all_steps):
		return "completed"
	if _has_step_status(all_steps, "available") or _has_step_status(all_steps, "completed"):
		return "available"
	if _is_planned_only_group(all_steps):
		return "locked"
	return "locked"


static func _group_status_key(group_index: int, intrinsic_status_key: String, prior_group_views: Array[Dictionary]) -> String:
	if intrinsic_status_key == "current":
		return "current"
	if intrinsic_status_key == "completed":
		return "completed"
	if group_index == 0:
		return "available"
	if group_index - 1 >= prior_group_views.size():
		return "locked"
	var previous_group_view: Dictionary = prior_group_views[group_index - 1]
	if str(previous_group_view.get("status_key", "locked")) == "completed" and intrinsic_status_key == "available":
		return "available"
	return "locked"


static func _has_step_status(steps: Array[Dictionary], status_key: String) -> bool:
	for step in steps:
		if str(step.get("status_key", "")) == status_key:
			return true
	return false


static func _all_trackable_steps_completed(steps: Array[Dictionary]) -> bool:
	var total := 0
	var completed := 0
	for step in steps:
		if _is_trackable_step(step):
			total += 1
			if str(step.get("status_key", "")) == "completed":
				completed += 1
	return total > 0 and completed >= total


static func _is_trackable_step(step: Dictionary) -> bool:
	var tracked_node_ids: Array[String] = _string_array(step.get("tracked_node_ids", []))
	var level_ids: Array[String] = _string_array(step.get("level_ids", []))
	if not tracked_node_ids.is_empty():
		return true
	if not level_ids.is_empty():
		return true
	if str(step.get("node_id", "")) != "":
		return true
	if str(step.get("challenge_id", "")) != "":
		return true
	if str(step.get("scene_id", "")) != "":
		return true
	return false


static func _is_planned_only_group(steps: Array[Dictionary]) -> bool:
	for step in steps:
		if _is_trackable_step(step):
			return false
	return true


static func _group_current_label(steps: Array[Dictionary]) -> String:
	for step in steps:
		if str(step.get("status_key", "")) == "current":
			return "Current flow: %s" % str(step.get("title", "Step"))
	return ""


static func _group_progress(steps: Array[Dictionary]) -> Dictionary:
	var total := 0
	var completed := 0
	for step in steps:
		if not _is_trackable_step(step):
			continue
		total += 1
		if str(step.get("status_key", "")) == "completed":
			completed += 1
	return {
		"completed": completed,
		"total": max(total, 1),
	}


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


static func _status_label(status_key: String) -> String:
	match status_key:
		"current":
			return "Current"
		"completed":
			return "Completed"
		"available":
			return "Available"
		_:
			return "Locked"


static func _group_status_label(status_key: String, is_planned_only: bool) -> String:
	if is_planned_only and status_key == "available":
		return "Planned"
	if is_planned_only and status_key == "locked":
		return "Queued"
	return _status_label(status_key)
