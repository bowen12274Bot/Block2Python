extends RefCounted
class_name QuestMapMapper

const QuestMapGroupCatalogScript = preload("res://scripts/map/catalog/quest_map_group_catalog.gd")
const QuestMapSlotMapperScript = preload("res://scripts/map/mappers/quest_map_slot_mapper.gd")
const StatusLabelHelperScript = preload("res://scripts/shared/status_label_helper.gd")


static func empty_map_view(message: String) -> Dictionary:
	return {
		"quest_title": "Quest Map",
		"mode_label": "Mode: -",
		"current_node_label": "Current Node: -",
		"summary": message,
		"group_summary": "0 groups visible | 0 active | 0 completed | 0 enterable",
		"groups": [],
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
	var demo_route_steps: Array[Dictionary] = QuestMapSlotMapperScript.step_dict_array(group.get("demo_route", []))
	var practice_route_steps: Array[Dictionary] = QuestMapSlotMapperScript.step_dict_array(group.get("practice_route", []))
	var demo_slot: Dictionary = QuestMapSlotMapperScript.map_slot(group.get("demo_slot", {}), "demo", "Demo")
	var practice_slot: Dictionary = QuestMapSlotMapperScript.map_slot(group.get("practice_slot", {}), "practice", "Practice")
	var story_step: Dictionary = QuestMapSlotMapperScript.first_step_by_type(demo_route_steps, "story")

	return {
		"group_id": group_id,
		"title": title,
		"subtitle": "Demo + Practice",
		"theme_title": QuestMapGroupCatalogScript.theme_title_for_group(group_id, title),
		"theme_description": QuestMapGroupCatalogScript.theme_description_for_group(group_id),
		"unlock_blocks": QuestMapGroupCatalogScript.unlock_blocks_for_group(group_id),
		"status_key": status_key,
		"status_label": str(group.get("status_label", StatusLabelHelperScript.label_for_status(status_key))),
		"is_enterable": bool(group.get("is_enterable", status_key != "locked")),
		"progress_label": _group_progress_label(demo_slot, practice_slot),
		"current_label": str(group.get("current_label", "")),
		"demo_route_steps": demo_route_steps,
		"story_step": story_step,
		"practice_route_steps": practice_route_steps,
		"demo_slot": demo_slot,
		"practice_slot": practice_slot,
	}


static func _group_progress_label(demo_slot: Dictionary, practice_slot: Dictionary) -> String:
	var demo_seen := "Seen" if bool(demo_slot.get("viewed", false)) else "Unseen"
	var practice_total: int = int(practice_slot.get("total_count", 0))
	var practice_completed: int = int(practice_slot.get("completed_count", 0))
	if not bool(practice_slot.get("is_unlocked", false)):
		return "Demo: %s | Practice: Locked" % demo_seen
	return "Demo: %s | Practice: %d / %d" % [demo_seen, practice_completed, max(practice_total, 1)]


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





