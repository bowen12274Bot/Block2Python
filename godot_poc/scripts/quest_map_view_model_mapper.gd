extends RefCounted
class_name QuestMapViewModelMapper

const QUEST_TITLE := "Basic IO Repair"
const GROUP_SPECS := [
	{
		"group_id": "group-01",
		"title": "Group 01",
		"subtitle": "Onboarding Route",
		"node_ids": [
			"map-entry",
			"story-intro",
			"demo-basic-io",
			"practice-basic-io",
			"result-basic-io",
		],
		"fallback_count": 5,
	},
	{
		"group_id": "group-02",
		"title": "Group 02",
		"subtitle": "Main Route Extension",
		"node_ids": [
			"next-main-node",
		],
		"fallback_count": 1,
	},
	{
		"group_id": "group-03",
		"title": "Group 03",
		"subtitle": "Reserved Next Arc",
		"node_ids": [],
		"fallback_count": 1,
	},
]
const NODE_SPECS := [
	{
		"node_id": "map-entry",
		"title": "Map Entry",
		"node_type": "entry",
		"prerequisite_node_ids": [],
	},
	{
		"node_id": "story-intro",
		"title": "City Alarm",
		"node_type": "story",
		"prerequisite_node_ids": ["map-entry"],
	},
	{
		"node_id": "demo-basic-io",
		"title": "Demo Route",
		"node_type": "demo",
		"prerequisite_node_ids": ["story-intro"],
	},
	{
		"node_id": "practice-basic-io",
		"title": "Practice Route",
		"node_type": "practice",
		"prerequisite_node_ids": ["demo-basic-io"],
	},
	{
		"node_id": "result-basic-io",
		"title": "Result Route",
		"node_type": "result",
		"prerequisite_node_ids": ["practice-basic-io"],
	},
	{
		"node_id": "next-main-node",
		"title": "Next Main Node",
		"node_type": "story",
		"prerequisite_node_ids": ["result-basic-io"],
	},
]


static func empty_map_view(message: String) -> Dictionary:
	var group_views: Array[Dictionary] = _build_group_views({}, {}, [])
	return {
		"quest_title": QUEST_TITLE,
		"mode_label": "Mode: -",
		"current_node_label": "Current Node: -",
		"summary": message,
		"group_summary": _build_group_summary(group_views),
		"groups": group_views,
		"show_legacy_nodes": false,
		"nodes": [],
	}


static func map_game_state(state: Dictionary) -> Dictionary:
	var completed_node_ids: Dictionary = _completed_node_lookup(state)
	var current_node_id: String = str(state.get("node_id", ""))
	var current_node_title: String = str(state.get("node_title", current_node_id))
	var mode_value: String = str(state.get("mode", ""))
	var node_views: Array[Dictionary] = []

	for node_spec_variant in NODE_SPECS:
		if not (node_spec_variant is Dictionary):
			continue

		var node_spec: Dictionary = node_spec_variant
		var node_id: String = str(node_spec.get("node_id", ""))
		var is_completed: bool = completed_node_ids.has(node_id)
		var is_current: bool = current_node_id != "" and current_node_id == node_id
		var is_available: bool = _is_available(node_spec, completed_node_ids, current_node_id)
		var status_key: String = _status_key(is_current, is_completed, is_available)

		node_views.append({
			"node_id": node_id,
			"title": str(node_spec.get("title", node_id)),
			"node_type": str(node_spec.get("node_type", "")),
			"status_key": status_key,
			"status_label": _status_label(status_key),
			"is_enterable": status_key != "locked",
		})

	var group_views: Array[Dictionary] = _build_group_views(state, completed_node_ids, node_views)
	var completed_count := completed_node_ids.size()
	return {
		"quest_title": QUEST_TITLE,
		"mode_label": "Mode: %s" % mode_value,
		"current_node_label": "Current Node: %s" % current_node_title,
		"summary": "Main map synced from live quest state. Completed %d nodes so far." % completed_count,
		"group_summary": _build_group_summary(group_views),
		"groups": group_views,
		"show_legacy_nodes": false,
		"nodes": node_views,
	}


static func _completed_node_lookup(state: Dictionary) -> Dictionary:
	var completed_node_ids: Dictionary = {}
	var progress_state: Variant = state.get("progress", {})
	if progress_state is Dictionary:
		var raw_completed_ids: Variant = progress_state.get("completed_node_ids", [])
		if raw_completed_ids is Array:
			for node_id_variant in raw_completed_ids:
				completed_node_ids[str(node_id_variant)] = true
	return completed_node_ids


static func _build_group_views(state: Dictionary, completed_node_ids: Dictionary, node_views: Array) -> Array[Dictionary]:
	var current_node_id: String = str(state.get("node_id", ""))
	var current_group_index := _find_current_group_index(current_node_id)
	var current_node_title: String = str(state.get("node_title", current_node_id))
	var group_views: Array[Dictionary] = []

	for index in GROUP_SPECS.size():
		var group_spec_variant: Variant = GROUP_SPECS[index]
		if not (group_spec_variant is Dictionary):
			continue

		var group_spec: Dictionary = group_spec_variant
		var group_node_ids: Array[String] = _string_array(group_spec.get("node_ids", []))
		var group_nodes: Array[Dictionary] = _find_node_views(group_node_ids, node_views)
		var completed_count := 0
		for node_view in group_nodes:
			if str(node_view.get("status_key", "")) == "completed":
				completed_count += 1

		var total_count := group_nodes.size()
		if total_count == 0:
			total_count = int(group_spec.get("fallback_count", 0))

		var is_current: bool = current_group_index == index
		var is_completed: bool = total_count > 0 and completed_count >= total_count
		var is_available: bool = _is_group_available(index, is_current, group_views)
		if is_completed:
			is_available = true

		var status_key := _status_key(is_current, is_completed, is_available)
		var current_label := ""
		if is_current and current_node_title != "":
			current_label = "Current flow: %s" % current_node_title
		elif group_nodes.is_empty() and index > current_group_index and current_group_index != -1:
			current_label = "Waiting for previous group to finish"

		var node_titles: Array[String] = []
		for node_view in group_nodes:
			node_titles.append(str(node_view.get("title", "")))

		group_views.append({
			"group_id": str(group_spec.get("group_id", "")),
			"title": str(group_spec.get("title", "Group")),
			"subtitle": str(group_spec.get("subtitle", "")),
			"status_key": status_key,
			"status_label": _group_status_label(status_key, group_nodes.is_empty()),
			"is_enterable": status_key != "locked",
			"progress_label": "Progress: %d / %d nodes" % [completed_count, total_count],
			"current_label": current_label,
			"node_titles": node_titles,
			"node_views": group_nodes,
		})

	return group_views


static func _is_group_available(group_index: int, is_current: bool, prior_group_views: Array[Dictionary]) -> bool:
	if is_current:
		return true
	if group_index == 0:
		return true
	if group_index - 1 >= prior_group_views.size():
		return false
	var previous_group_view: Dictionary = prior_group_views[group_index - 1]
	return str(previous_group_view.get("status_key", "locked")) == "completed"


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


static func _find_current_group_index(current_node_id: String) -> int:
	if current_node_id == "":
		return -1
	for index in GROUP_SPECS.size():
		var group_spec_variant: Variant = GROUP_SPECS[index]
		if not (group_spec_variant is Dictionary):
			continue
		var group_spec: Dictionary = group_spec_variant
		var node_ids: Array[String] = _string_array(group_spec.get("node_ids", []))
		if node_ids.has(current_node_id):
			return index
	return -1


static func _find_node_views(group_node_ids: Array[String], node_views: Array) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	for group_node_id in group_node_ids:
		for node_view_variant in node_views:
			if not (node_view_variant is Dictionary):
				continue
			var node_view: Dictionary = node_view_variant
			if str(node_view.get("node_id", "")) == group_node_id:
				results.append(node_view)
				break
	return results


static func _string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item in value:
			result.append(str(item))
	return result


static func _is_available(node_spec: Dictionary, completed_node_ids: Dictionary, current_node_id: String) -> bool:
	var node_id: String = str(node_spec.get("node_id", ""))
	if node_id != "" and node_id == current_node_id:
		return true

	var prerequisites: Variant = node_spec.get("prerequisite_node_ids", [])
	if prerequisites is Array:
		for prerequisite_variant in prerequisites:
			if not completed_node_ids.has(str(prerequisite_variant)):
				return false

	return true


static func _status_key(is_current: bool, is_completed: bool, is_available: bool) -> String:
	if is_current:
		return "current"
	if is_completed:
		return "completed"
	if is_available:
		return "available"
	return "locked"


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
