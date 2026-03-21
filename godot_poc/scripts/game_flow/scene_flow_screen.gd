extends Control
class_name SceneFlowScreen

signal advance_requested()
signal back_requested()

@onready var status_label: Label = $Margin/Scroll/Root/StatusLabel
@onready var scene_panel: ScenePanel = $Margin/Scroll/Root/ScenePanel
@onready var advance_button: Button = $Margin/Scroll/Root/Buttons/AdvanceButton
@onready var back_button: Button = $Margin/Scroll/Root/Buttons/BackButton


func _ready() -> void:
	advance_button.pressed.connect(_on_advance_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)


func show_scene(scene_view: Dictionary) -> void:
	scene_panel.show_scene(scene_view)


func show_placeholder(message: String) -> void:
	scene_panel.show_placeholder(message)


func set_status(text: String) -> void:
	status_label.text = text


func set_can_advance(can_advance: bool) -> void:
	advance_button.disabled = not can_advance


func set_can_go_back(can_go_back: bool) -> void:
	back_button.disabled = not can_go_back


func _on_advance_button_pressed() -> void:
	status_label.text = "Status: requesting advance..."
	advance_requested.emit()


func _on_back_button_pressed() -> void:
	status_label.text = "Status: returning to map..."
	back_requested.emit()
