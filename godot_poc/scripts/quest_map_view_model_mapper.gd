extends RefCounted
class_name QuestMapViewModelMapper

const QUEST_TITLE := "Basic IO Repair"
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
        "title": "Demo Challenge",
        "node_type": "demo",
        "prerequisite_node_ids": ["story-intro"],
    },
    {
        "node_id": "practice-basic-io",
        "title": "Practice Challenge",
        "node_type": "practice",
        "prerequisite_node_ids": ["demo-basic-io"],
    },
    {
        "node_id": "result-basic-io",
        "title": "Result Node",
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
    return {
        "quest_title": QUEST_TITLE,
        "mode_label": "Mode: -",
        "current_node_label": "Current Node: -",
        "summary": message,
        "nodes": [],
    }


static func map_game_state(state: Dictionary) -> Dictionary:
    var progress_state: Variant = state.get("progress", {})
    var completed_node_ids: Dictionary = {}
    if progress_state is Dictionary:
        var raw_completed_ids: Variant = progress_state.get("completed_node_ids", [])
        if raw_completed_ids is Array:
            for node_id_variant in raw_completed_ids:
                completed_node_ids[str(node_id_variant)] = true

    var current_node_id: String = str(state.get("node_id", ""))
    var mode_value: String = str(state.get("mode", ""))
    var node_views: Array[Dictionary] = []
    var available_count := 0
    var completed_count := completed_node_ids.size()

    for node_spec_variant in NODE_SPECS:
        if not (node_spec_variant is Dictionary):
            continue

        var node_spec: Dictionary = node_spec_variant
        var node_id: String = str(node_spec.get("node_id", ""))
        var is_completed: bool = completed_node_ids.has(node_id)
        var is_current: bool = current_node_id != "" and current_node_id == node_id
        var is_available: bool = _is_available(node_spec, completed_node_ids, current_node_id)
        var status_key: String = _status_key(is_current, is_completed, is_available)
        if is_available:
            available_count += 1

        node_views.append({
            "node_id": node_id,
            "title": str(node_spec.get("title", node_id)),
            "node_type": str(node_spec.get("node_type", "")),
            "status_key": status_key,
            "status_label": _status_label(status_key),
            "is_enterable": status_key != "locked",
        })

    return {
        "quest_title": QUEST_TITLE,
        "mode_label": "Mode: %s" % mode_value,
        "current_node_label": "Current Node: %s" % str(state.get("node_title", current_node_id)),
        "summary": "Completed %d / %d nodes | Enterable %d" % [completed_count, NODE_SPECS.size(), available_count],
        "nodes": node_views,
    }


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
