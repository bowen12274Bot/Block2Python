extends RefCounted
class_name QuestMapSelectionPresenter


static func build_group_selection_note(group_view: Dictionary) -> String:
	if group_view.is_empty():
		return "Selected level group."

	var lines: Array[String] = []
	lines.append("Selected level group: %s" % str(group_view.get("title", group_view.get("group_id", "-"))))
	lines.append("Status: %s" % str(group_view.get("status_label", "Unknown")))
	lines.append(str(group_view.get("progress_label", "")))
	var current_label: String = str(group_view.get("current_label", ""))
	if current_label != "":
		lines.append(current_label)

	_append_slot_note(lines, group_view.get("demo_slot", {}))
	_append_slot_note(lines, group_view.get("practice_slot", {}))

	var status_key: String = str(group_view.get("status_key", "locked"))
	if status_key == "locked":
		lines.append("This group is not enterable yet.")
		return "\n\n".join(lines)

	var next_step: Dictionary = preferred_route_step(group_view)
	if status_key == "current" and not next_step.is_empty():
		lines.append("Opening current route step: %s" % str(next_step.get("title", "Step")))
	else:
		lines.append("Opening route preview from the selected group. This does not change bridge state yet.")

	return "\n\n".join(lines)


static func build_node_selection_note(node_id: String) -> String:
	return "Selected quest node: %s\n\nLegacy node cards are being phased out. Route steps on the map are now driven by bridge map_route data." % node_id


static func preferred_route_step(group_view: Dictionary) -> Dictionary:
	var demo_slot_variant: Variant = group_view.get("demo_slot", {})
	if demo_slot_variant is Dictionary:
		var demo_slot: Dictionary = demo_slot_variant
		var primary_step_variant: Variant = demo_slot.get("primary_step", {})
		if primary_step_variant is Dictionary and not primary_step_variant.is_empty():
			return primary_step_variant
	var practice_slot_variant: Variant = group_view.get("practice_slot", {})
	if practice_slot_variant is Dictionary:
		var practice_slot: Dictionary = practice_slot_variant
		var primary_step_variant: Variant = practice_slot.get("primary_step", {})
		if primary_step_variant is Dictionary and not primary_step_variant.is_empty():
			return primary_step_variant
	return {}


static func build_group_route_scene_view(group_view: Dictionary, preferred_step: Dictionary) -> Dictionary:
	var body_lines: Array[String] = []
	body_lines.append("Status: %s" % str(group_view.get("status_label", "Unknown")))
	body_lines.append(str(group_view.get("progress_label", "")))
	var current_label: String = str(group_view.get("current_label", ""))
	if current_label != "":
		body_lines.append(current_label)

	_append_slot_section(body_lines, group_view.get("demo_slot", {}))
	body_lines.append("")
	_append_slot_section(body_lines, group_view.get("practice_slot", {}))

	if not preferred_step.is_empty():
		body_lines.append("")
		body_lines.append("Selected step: %s [%s]" % [str(preferred_step.get("title", "Step")), str(preferred_step.get("status_label", "Unknown"))])
		body_lines.append("Target page: %s" % str(preferred_step.get("target_page", "map")))

	body_lines.append("")
	body_lines.append("This preview route is local to the Godot client. It does not change the bridge GameState.")

	return {
		"mode_label": "Mode: group-route",
		"node_label": "Group: %s" % str(group_view.get("group_id", "-")),
		"title": str(group_view.get("title", "Group Route")),
		"body": "\n".join(body_lines),
	}


static func _append_slot_section(body_lines: Array[String], slot_variant: Variant) -> void:
	if not (slot_variant is Dictionary):
		return
	var slot: Dictionary = slot_variant
	if slot.is_empty():
		return
	body_lines.append("%s [%s | %s]:" % [str(slot.get("title", "Slot")), str(slot.get("status_label", "Unknown")), str(slot.get("progress_label", "0 / 0"))])
	var route_steps_variant: Variant = slot.get("route_steps", [])
	if route_steps_variant is Array:
		for step in route_steps_variant:
			if step is Dictionary:
				body_lines.append("- %s [%s]" % [str(step.get("title", "Step")), str(step.get("status_label", "Unknown"))])
	var practice_levels_variant: Variant = slot.get("practice_levels", [])
	if practice_levels_variant is Array and not practice_levels_variant.is_empty():
		body_lines.append("Practice Levels:")
		for level_variant in practice_levels_variant:
			if level_variant is Dictionary:
				body_lines.append("- %s [%s]" % [str(level_variant.get("title", "Level")), str(level_variant.get("status_label", "Unknown"))])


static func _append_slot_note(lines: Array[String], slot_variant: Variant) -> void:
	if not (slot_variant is Dictionary):
		return
	var slot: Dictionary = slot_variant
	if slot.is_empty():
		return
	lines.append("%s: %s [%s]" % [str(slot.get("title", "Slot")), str(slot.get("progress_label", "0 / 0")), str(slot.get("status_label", "Unknown"))])
	var primary_step_variant: Variant = slot.get("primary_step", {})
	if primary_step_variant is Dictionary:
		var primary_step: Dictionary = primary_step_variant
		if not primary_step.is_empty():
			lines.append("%s entry: %s" % [str(slot.get("title", "Slot")), str(primary_step.get("title", "Step"))])
	var practice_levels_variant: Variant = slot.get("practice_levels", [])
	if practice_levels_variant is Array and not practice_levels_variant.is_empty():
		var practice_labels: PackedStringArray = []
		for level_variant in practice_levels_variant:
			if level_variant is Dictionary:
				practice_labels.append("%s[%s]" % [str(level_variant.get("title", "Level")), str(level_variant.get("status_label", "Unknown"))])
		lines.append("Practice Levels: %s" % ", ".join(practice_labels))
