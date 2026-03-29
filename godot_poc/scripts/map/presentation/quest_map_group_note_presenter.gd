extends RefCounted
class_name QuestMapGroupNotePresenter


static func build_group_selection_note(group_view: Dictionary) -> String:
	if group_view.is_empty():
		return "Selected level group."

	var lines: Array[String] = []
	lines.append("Selected level group: %s" % str(group_view.get("title", group_view.get("group_id", "-"))))
	lines.append("Status: %s" % str(group_view.get("status_label", "Unknown")))
	var progress_label: String = str(group_view.get("progress_label", ""))
	if progress_label != "":
		lines.append(progress_label)
	var current_label: String = str(group_view.get("current_label", ""))
	if current_label != "":
		lines.append(current_label)

	_append_slot_note(lines, group_view.get("demo_slot", {}))
	_append_slot_note(lines, group_view.get("practice_slot", {}))

	var status_key: String = str(group_view.get("status_key", "locked"))
	if status_key == "locked":
		lines.append("This group is not enterable yet.")
	else:
		lines.append("Opening the stage overlay for Story / Demo / Practice selection.")

	return "\n\n".join(lines)



static func _append_slot_note(lines: Array[String], slot_variant: Variant) -> void:
	if not (slot_variant is Dictionary):
		return
	var slot: Dictionary = slot_variant
	if slot.is_empty():
		return
	lines.append("%s: %s [%s]" % [str(slot.get("title", "Slot")), str(slot.get("progress_label", "0 / 0")), str(slot.get("status_label", "Unknown"))])
	if str(slot.get("slot_key", "")) == "demo":
		lines.append("Demo: %s" % ("Seen" if bool(slot.get("viewed", false)) else "Unseen"))
		lines.append("Demo access: %s" % ("Available" if bool(slot.get("is_unlocked", false)) else "Locked until Story clears"))
	if str(slot.get("slot_key", "")) == "practice":
		lines.append("Practice: %s" % ("Available" if bool(slot.get("is_unlocked", false)) else "Locked"))
		var entry_level_id: String = str(slot.get("entry_level_id", ""))
		if entry_level_id != "":
			lines.append("Practice entry level: %s" % entry_level_id)
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

