extends Control
class_name QuestMapScreen

const QuestMapSelectionPresenterScript = preload("res://scripts/map/quest_map_selection_presenter.gd")

signal start_bridge_requested()
signal reset_requested()
signal advance_requested()
signal node_open_requested()
signal debug_toggled(visible: bool)
signal group_route_requested(group_view: Dictionary)

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

	note_label.text = QuestMapSelectionPresenterScript.build_group_selection_note(group_view)
	group_route_requested.emit(group_view)


func _on_node_pressed(node_id: String) -> void:
	if note_label != null:
		note_label.text = QuestMapSelectionPresenterScript.build_node_selection_note(node_id)


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
