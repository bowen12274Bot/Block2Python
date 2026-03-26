extends Control
class_name QuestMapScreen

const QuestMapPanelScript = preload("res://scripts/quest_map_panel.gd")

signal start_bridge_requested()
signal reset_requested()
signal advance_requested()
signal node_open_requested()
signal debug_toggled(visible: bool)

@onready var start_bridge_button: Button = $Margin/Root/Buttons/StartBridgeButton
@onready var reset_button: Button = $Margin/Root/Buttons/ResetButton
@onready var advance_button: Button = $Margin/Root/Buttons/AdvanceButton
@onready var open_node_button: Button = $Margin/Root/Buttons/OpenNodeButton
@onready var debug_toggle_button: Button = $Margin/Root/Buttons/DebugToggleButton
@onready var status_label: Label = $Margin/Root/StatusLabel
@onready var quest_map_panel: QuestMapPanelScript = $Margin/Root/QuestMapPanel
@onready var note_label: Label = $Margin/Root/NotePanel/NoteMargin/NoteRoot/NoteText


func _ready() -> void:
	start_bridge_button.pressed.connect(func() -> void:
		start_bridge_requested.emit()
	)
	reset_button.pressed.connect(func() -> void:
		reset_requested.emit()
	)
	advance_button.pressed.connect(func() -> void:
		advance_requested.emit()
	)
	open_node_button.pressed.connect(func() -> void:
		node_open_requested.emit()
	)
	debug_toggle_button.toggled.connect(func(button_pressed: bool) -> void:
		debug_toggled.emit(button_pressed)
	)


func show_map(map_view: Dictionary) -> void:
	quest_map_panel.show_map(map_view)


func set_status(text: String) -> void:
	status_label.text = text


func set_note(text: String) -> void:
	note_label.text = text


func set_bridge_running(is_running: bool) -> void:
	start_bridge_button.disabled = is_running
	reset_button.disabled = not is_running
	advance_button.disabled = not is_running


func set_current_node_enterable(is_enterable: bool) -> void:
	open_node_button.disabled = not is_enterable


func set_can_advance(can_advance: bool) -> void:
	advance_button.disabled = not can_advance


func set_debug_visible(debug_visible: bool) -> void:
	debug_toggle_button.button_pressed = debug_visible
	debug_toggle_button.text = "Hide Debug" if debug_visible else "Show Debug"
