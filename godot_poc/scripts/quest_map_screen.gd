extends Control
class_name QuestMapScreen

signal start_bridge_requested()
signal reset_requested()
signal advance_requested()
signal node_open_requested()
signal debug_toggled(visible: bool)

@onready var start_bridge_button: Button = get_node_or_null("Margin/Scroll/Root/Buttons/StartBridgeButton")
@onready var reset_button: Button = get_node_or_null("Margin/Scroll/Root/Buttons/ResetButton")
@onready var advance_button: Button = get_node_or_null("Margin/Scroll/Root/Buttons/AdvanceButton")
@onready var open_node_button: Button = get_node_or_null("Margin/Scroll/Root/Buttons/OpenNodeButton")
@onready var debug_toggle_button: Button = get_node_or_null("Margin/Scroll/Root/Buttons/DebugToggleButton")
@onready var status_label: Label = get_node_or_null("Margin/Scroll/Root/StatusLabel")
@onready var quest_map_panel: QuestMapPanel = get_node_or_null("Margin/Scroll/Root/QuestMapPanel")
@onready var note_label: Label = get_node_or_null("Margin/Scroll/Root/NotePanel/NoteMargin/NoteRoot/NoteText")

var _last_map_view: Dictionary = {}


func _ready() -> void:
	if start_bridge_button != null:
		start_bridge_button.pressed.connect(func() -> void:
			start_bridge_requested.emit()
		)
	if reset_button != null:
		reset_button.pressed.connect(func() -> void:
			reset_requested.emit()
		)
	if advance_button != null:
		advance_button.pressed.connect(func() -> void:
			advance_requested.emit()
		)
		advance_button.disabled = true
	if open_node_button != null:
		open_node_button.pressed.connect(func() -> void:
			node_open_requested.emit()
		)
		open_node_button.disabled = true
	if debug_toggle_button != null:
		debug_toggle_button.toggled.connect(func(button_pressed: bool) -> void:
			debug_toggled.emit(button_pressed)
		)
	if quest_map_panel != null:
		quest_map_panel.group_pressed.connect(_on_group_pressed)
		quest_map_panel.node_pressed.connect(_on_node_pressed)


func show_map(map_view: Dictionary) -> void:
	_last_map_view = map_view.duplicate(true)
	if quest_map_panel != null:
		quest_map_panel.show_map(map_view)


func set_status(text: String) -> void:
	if status_label != null:
		status_label.text = text


func set_note(text: String) -> void:
	if note_label != null:
		note_label.text = text


func set_bridge_running(is_running: bool) -> void:
	if start_bridge_button != null:
		start_bridge_button.disabled = is_running
	if reset_button != null:
		reset_button.disabled = not is_running
	if advance_button != null:
		advance_button.disabled = true
	if open_node_button != null:
		open_node_button.disabled = true


func set_current_node_enterable(is_enterable: bool) -> void:
	if open_node_button != null:
		open_node_button.disabled = not is_enterable


func set_can_advance(can_advance: bool) -> void:
	if advance_button != null:
		advance_button.disabled = not can_advance


func set_debug_visible(debug_visible: bool) -> void:
	if debug_toggle_button != null:
		debug_toggle_button.button_pressed = debug_visible
		debug_toggle_button.text = "Hide Debug" if debug_visible else "Show Debug"


func _on_group_pressed(group_id: String) -> void:
	if note_label == null:
		return

	var group_view: Dictionary = _find_group_view(group_id)
	if group_view.is_empty():
		note_label.text = "Selected level group: %s" % group_id
		return

	var lines: Array[String] = []
	lines.append("Selected level group: %s" % str(group_view.get("title", group_id)))
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
		note_label.text = "\n\n".join(lines)
		return

	var next_step: Dictionary = _preferred_route_step(group_view)
	if status_key == "current" and not next_step.is_empty():
		lines.append("Opening current route step: %s" % str(next_step.get("title", "Step")))
	else:
		lines.append("Opening route preview from the selected group. This does not change bridge state yet.")

	note_label.text = "\n\n".join(lines)
	_route_group_from_map(group_view)


func _append_slot_note(lines: Array[String], slot_variant: Variant) -> void:
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


func _on_node_pressed(node_id: String) -> void:
	if note_label != null:
		note_label.text = "Selected quest node: %s\n\nLegacy node cards are being phased out. Route steps on the map are now driven by bridge map_route data." % node_id


func _find_group_view(group_id: String) -> Dictionary:
	var groups: Variant = _last_map_view.get("groups", [])
	if groups is Array:
		for group_view_variant in groups:
			if not (group_view_variant is Dictionary):
				continue
			var group_view: Dictionary = group_view_variant
			if str(group_view.get("group_id", "")) == group_id:
				return group_view
	return {}


func _preferred_route_step(group_view: Dictionary) -> Dictionary:
	var demo_slot_variant: Variant = group_view.get("demo_slot", {})
	if demo_slot_variant is Dictionary:
		var demo_slot: Dictionary = demo_slot_variant
		var primary_step_variant: Variant = demo_slot.get("primary_step", {})
		if primary_step_variant is Dictionary and not primary_step_variant.is_empty():
			return primary_step_variant
	var practice_slot_variant: Variant = group_view.get("practice_slot", {})
	if practice_slot_variant is Dictionary:
		var practice_slot: Dictionary = practice_slot_variant
		var practice_step_variant: Variant = practice_slot.get("primary_step", {})
		if practice_step_variant is Dictionary and not practice_step_variant.is_empty():
			return practice_step_variant
	return {}


func _route_group_from_map(group_view: Dictionary) -> void:
	var coordinator: Node = get_parent()
	if coordinator != null and coordinator.has_method("_on_group_route_requested"):
		coordinator.call("_on_group_route_requested", group_view)
