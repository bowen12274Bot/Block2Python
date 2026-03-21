extends Control
class_name SceneFlowScreen

signal advance_requested()
signal back_requested()

@onready var scene_panel: ScenePanel = $ScenePanel
@onready var advance_button: Button = $Buttons/AdvanceButton
@onready var skip_button: Button = $Buttons/SkipButton
@onready var back_button: Button = $Buttons/BackButton


func _ready() -> void:
	advance_button.pressed.connect(_on_advance_button_pressed)
	skip_button.pressed.connect(_on_skip_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)
	scene_panel.continue_requested.connect(_on_continue_requested)


func show_scene(scene_view: Dictionary) -> void:
	scene_panel.show_scene(scene_view)


func show_placeholder(message: String) -> void:
	scene_panel.show_placeholder(message)


func set_status(text: String) -> void:
	scene_panel.set_status_overlay(text)


func set_can_advance(can_advance: bool) -> void:
	advance_button.disabled = not can_advance
	skip_button.disabled = not can_advance


func set_can_go_back(can_go_back: bool) -> void:
	back_button.disabled = not can_go_back


func _on_continue_requested() -> void:
	_handle_story_continue()


func _handle_story_continue() -> void:
	if not scene_panel.can_continue_story():
		return
	if scene_panel.continue_story():
		scene_panel.set_status_overlay("Status: story segment complete...")
		advance_requested.emit()


func _on_advance_button_pressed() -> void:
	scene_panel.set_status_overlay("Status: developer advance...")
	advance_requested.emit()


func _on_skip_button_pressed() -> void:
	scene_panel.set_status_overlay("Status: skipping story...")
	advance_requested.emit()


func _on_back_button_pressed() -> void:
	scene_panel.set_status_overlay("Status: returning to map...")
	back_requested.emit()
