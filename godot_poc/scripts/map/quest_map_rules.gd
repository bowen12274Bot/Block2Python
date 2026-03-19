extends RefCounted
class_name QuestMapRules


static func slot_status_key(route_steps: Array[Dictionary]) -> String:
	if has_step_status(route_steps, "current"):
		return "current"
	if all_trackable_steps_completed(route_steps):
		return "completed"
	if has_step_status(route_steps, "available") or has_step_status(route_steps, "completed"):
		return "available"
	return "locked"


static func primary_slot_step(route_steps: Array[Dictionary]) -> Dictionary:
	for step in route_steps:
		if str(step.get("status_key", "")) == "current":
			return step
	for step in route_steps:
		var status_key: String = str(step.get("status_key", ""))
		if status_key == "available" or status_key == "completed":
			return step
	return {}


static func slot_progress(route_steps: Array[Dictionary], cleared_level_ids: Array[String] = []) -> Dictionary:
	var tracked_steps: Array[Dictionary] = []
	for step in route_steps:
		if is_trackable_step(step):
			tracked_steps.append(step)
	if tracked_steps.is_empty():
		return {"completed": 0, "total": 1}
	var primary_step: Dictionary = primary_slot_step(route_steps)
	var level_ids: Array[String] = _string_array(primary_step.get("level_ids", []))
	if level_ids.size() > 1:
		var completed_levels := 0
		var level_views: Array[Dictionary] = practice_levels(route_steps, cleared_level_ids)
		for level_view in level_views:
			if str(level_view.get("status_key", "")) == "completed":
				completed_levels += 1
		return {"completed": completed_levels, "total": level_ids.size()}
	var completed := 0
	for step in tracked_steps:
		if str(step.get("status_key", "")) == "completed":
			completed += 1
	return {"completed": completed, "total": tracked_steps.size()}


static func practice_levels(route_steps: Array[Dictionary], cleared_level_ids: Array[String] = []) -> Array[Dictionary]:
	var primary_step: Dictionary = primary_slot_step(route_steps)
	var level_ids: Array[String] = _string_array(primary_step.get("level_ids", []))
	var results: Array[Dictionary] = []
	var unlocked := false
	for index in level_ids.size():
		var level_id: String = level_ids[index]
		var level_status_key: String = "locked"
		if level_id in cleared_level_ids:
			level_status_key = "completed"
			unlocked = true
		elif not unlocked:
			level_status_key = "available"
			unlocked = true
		results.append({
			"level_id": level_id,
			"title": "Practice %02d" % [index + 1],
			"status_key": level_status_key,
			"status_label": status_label(level_status_key),
		})
	return results


static func intrinsic_group_status_key(all_steps: Array[Dictionary]) -> String:
	if has_step_status(all_steps, "current"):
		return "current"
	if all_trackable_steps_completed(all_steps):
		return "completed"
	if has_step_status(all_steps, "available") or has_step_status(all_steps, "completed"):
		return "available"
	if is_planned_only_group(all_steps):
		return "locked"
	return "locked"


static func group_status_key(group_index: int, intrinsic_status_key: String, prior_group_views: Array[Dictionary]) -> String:
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


static func group_current_label(steps: Array[Dictionary]) -> String:
	for step in steps:
		if str(step.get("status_key", "")) == "current":
			return "Current flow: %s" % str(step.get("title", "Step"))
	return ""


static func group_progress(steps: Array[Dictionary]) -> Dictionary:
	var total := 0
	var completed := 0
	for step in steps:
		if not is_trackable_step(step):
			continue
		total += 1
		if str(step.get("status_key", "")) == "completed":
			completed += 1
	return {
		"completed": completed,
		"total": max(total, 1),
	}


static func tracked_titles(demo_route_steps: Array[Dictionary], practice_route_steps: Array[Dictionary]) -> Array[String]:
	var results: Array[String] = []
	var seen: Dictionary = {}
	for step in demo_route_steps:
		_append_unique_title(results, seen, step)
	for step in practice_route_steps:
		_append_unique_title(results, seen, step)
	return results


static func has_step_status(steps: Array[Dictionary], status_key: String) -> bool:
	for step in steps:
		if str(step.get("status_key", "")) == status_key:
			return true
	return false


static func all_trackable_steps_completed(steps: Array[Dictionary]) -> bool:
	var total := 0
	var completed := 0
	for step in steps:
		if is_trackable_step(step):
			total += 1
			if str(step.get("status_key", "")) == "completed":
				completed += 1
	return total > 0 and completed >= total


static func is_trackable_step(step: Dictionary) -> bool:
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


static func is_planned_only_group(steps: Array[Dictionary]) -> bool:
	for step in steps:
		if is_trackable_step(step):
			return false
	return true


static func status_label(status_key: String) -> String:
	match status_key:
		"current":
			return "Current"
		"completed":
			return "Completed"
		"available":
			return "Available"
		_:
			return "Locked"


static func group_status_label(status_key: String, is_planned_only: bool) -> String:
	if is_planned_only and status_key == "available":
		return "Planned"
	if is_planned_only and status_key == "locked":
		return "Queued"
	return status_label(status_key)


static func _append_unique_title(results: Array[String], seen: Dictionary, step: Dictionary) -> void:
	if not is_trackable_step(step):
		return
	var title: String = str(step.get("title", ""))
	if title == "" or seen.has(title):
		return
	seen[title] = true
	results.append(title)


static func _string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item in value:
			result.append(str(item))
	return result
