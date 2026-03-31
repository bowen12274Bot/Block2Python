@tool
extends Control
class_name SceneFlowScreen

const ScenePanelScript = preload("res://scripts/game_flow/ui/scene_panel.gd")

signal advance_requested()
signal back_requested()

@export_group("Mission Brief Art")
@export_file("*.png", "*.jpg", "*.jpeg", "*.webp") var mission_background_source_path: String = "res://art/task/background.png":
	set(value):
		mission_background_source_path = value
		_refresh_mission_art()
@export_file("*.png", "*.jpg", "*.jpeg", "*.webp") var mission_agree_button_source_path: String = "res://art/task/agree.png":
	set(value):
		mission_agree_button_source_path = value
		_refresh_mission_art()

@onready var scene_panel: ScenePanelScript = $ScenePanel
@onready var advance_button: Button = $Buttons/AdvanceButton
@onready var skip_button: Button = $Buttons/SkipButton
@onready var back_button: Button = $Buttons/BackButton
@onready var mission_overlay: Control = get_node_or_null("MissionOverlay")
@onready var mission_background: TextureRect = get_node_or_null("MissionOverlay/Center/MissionPanel/MissionBackground")
@onready var mission_title_label: Label = get_node_or_null("MissionOverlay/Center/MissionPanel/MissionContent/MissionRoot/MissionTitle")
@onready var mission_body_label: RichTextLabel = get_node_or_null("MissionOverlay/Center/MissionPanel/MissionContent/MissionRoot/MissionBody")
@onready var mission_agree_button: Button = get_node_or_null("MissionOverlay/Center/MissionPanel/MissionContent/MissionRoot/MissionAgreeButton")
@onready var mission_agree_button_art: TextureRect = get_node_or_null("MissionOverlay/Center/MissionPanel/MissionContent/MissionRoot/MissionAgreeButton/AgreeButtonArt")

var _can_advance: bool = false
var _can_go_back: bool = false
var _mission_brief_visible: bool = false
var _show_mission_brief_on_complete: bool = false
var _mission_brief_title: String = "Mission"
var _mission_brief_text: String = ""
var _mission_agree_button_hovered: bool = false
var _mission_agree_button_pressed: bool = false


func _ready() -> void:
	_refresh_mission_art()
	advance_button.pressed.connect(_on_advance_button_pressed)
	skip_button.pressed.connect(_on_skip_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)
	if mission_agree_button != null:
		mission_agree_button.pressed.connect(_on_mission_agree_button_pressed)
		mission_agree_button.mouse_entered.connect(_on_mission_agree_button_mouse_entered)
		mission_agree_button.mouse_exited.connect(_on_mission_agree_button_mouse_exited)
		mission_agree_button.button_down.connect(_on_mission_agree_button_button_down)
		mission_agree_button.button_up.connect(_on_mission_agree_button_button_up)
	scene_panel.continue_requested.connect(_on_continue_requested)
	_hide_mission_brief()
	_update_mission_agree_button_visual()


func show_scene(scene_view: Dictionary) -> void:
	scene_panel.show_scene(scene_view)
	_show_mission_brief_on_complete = bool(scene_view.get("show_mission_brief_on_complete", false))
	_mission_brief_title = str(scene_view.get("mission_brief_title", "Mission"))
	_mission_brief_text = str(scene_view.get("mission_brief_text", ""))
	_hide_mission_brief()
	_refresh_button_state()


func show_placeholder(message: String) -> void:
	scene_panel.show_placeholder(message)
	_show_mission_brief_on_complete = false
	_mission_brief_title = "Mission"
	_mission_brief_text = ""
	_hide_mission_brief()
	_refresh_button_state()


func set_status(text: String) -> void:
	if _mission_brief_visible:
		return
	scene_panel.set_status_overlay(text)


func set_can_advance(can_advance: bool) -> void:
	_can_advance = can_advance
	_refresh_button_state()


func set_can_go_back(can_go_back: bool) -> void:
	_can_go_back = can_go_back
	_refresh_button_state()


func _on_continue_requested() -> void:
	if _mission_brief_visible:
		return
	_handle_story_continue()


func _handle_story_continue() -> void:
	if not scene_panel.can_continue_story():
		return
	if scene_panel.continue_story():
		if _show_mission_brief_on_complete:
			_show_mission_brief()
			return
		scene_panel.set_status_overlay("Status: story segment complete...")
		advance_requested.emit()


func _on_advance_button_pressed() -> void:
	if _mission_brief_visible:
		return
	scene_panel.set_status_overlay("Status: developer advance...")
	advance_requested.emit()


func _on_skip_button_pressed() -> void:
	if _mission_brief_visible:
		return
	scene_panel.set_status_overlay("Status: skipping story...")
	advance_requested.emit()


func _on_back_button_pressed() -> void:
	if _mission_brief_visible:
		return
	scene_panel.set_status_overlay("Status: returning to map...")
	back_requested.emit()


func _on_mission_agree_button_pressed() -> void:
	_hide_mission_brief()
	scene_panel.set_status_overlay("Status: mission accepted...")
	advance_requested.emit()


func _on_mission_agree_button_mouse_entered() -> void:
	_mission_agree_button_hovered = true
	_update_mission_agree_button_visual()


func _on_mission_agree_button_mouse_exited() -> void:
	_mission_agree_button_hovered = false
	_mission_agree_button_pressed = false
	_update_mission_agree_button_visual()


func _on_mission_agree_button_button_down() -> void:
	_mission_agree_button_pressed = true
	_update_mission_agree_button_visual()


func _on_mission_agree_button_button_up() -> void:
	_mission_agree_button_pressed = false
	_update_mission_agree_button_visual()


func _show_mission_brief() -> void:
	_mission_brief_visible = true
	if mission_title_label != null:
		mission_title_label.text = _mission_brief_title
	if mission_body_label != null:
		mission_body_label.text = _mission_brief_body_text()
	if mission_overlay != null:
		mission_overlay.visible = true
	scene_panel.set_status_overlay("")
	_refresh_button_state()
	if mission_agree_button != null:
		mission_agree_button.grab_focus()


func _hide_mission_brief() -> void:
	_mission_brief_visible = false
	if mission_overlay != null:
		mission_overlay.visible = false
	_refresh_button_state()


func _refresh_button_state() -> void:
	var locked_by_mission: bool = _mission_brief_visible
	if advance_button != null:
		advance_button.disabled = locked_by_mission or not _can_advance
	if skip_button != null:
		skip_button.disabled = locked_by_mission or not _can_advance
	if back_button != null:
		back_button.disabled = locked_by_mission or not _can_go_back
	_update_mission_agree_button_visual()


func _mission_brief_body_text() -> String:
	if _mission_brief_text.strip_edges() != "":
		return _mission_brief_text
	return "Read the mission briefing, then press Agree to enter the demo page."


func _refresh_mission_art() -> void:
	if not is_node_ready():
		return
	_apply_task_background()
	_apply_task_agree_button_art()
	_update_mission_agree_button_visual()


func _apply_task_background() -> void:
	if mission_background == null:
		return

	if mission_background_source_path.strip_edges() == "":
		mission_background.texture = null
		return

	var image: Image = _load_image_from_source(ProjectSettings.globalize_path(mission_background_source_path))
	if image == null or image.is_empty():
		if ResourceLoader.exists(mission_background_source_path):
			mission_background.texture = load(mission_background_source_path)
		return

	mission_background.texture = ImageTexture.create_from_image(image)


func _apply_task_agree_button_art() -> void:
	if mission_agree_button_art == null:
		return

	if mission_agree_button_source_path.strip_edges() == "":
		mission_agree_button_art.texture = null
		return

	var image: Image = _load_image_from_source(ProjectSettings.globalize_path(mission_agree_button_source_path))
	if image == null or image.is_empty():
		if ResourceLoader.exists(mission_agree_button_source_path):
			mission_agree_button_art.texture = load(mission_agree_button_source_path)
		return

	mission_agree_button_art.texture = ImageTexture.create_from_image(image)


func _update_mission_agree_button_visual() -> void:
	if mission_agree_button_art == null:
		return

	if mission_agree_button != null and mission_agree_button.disabled:
		mission_agree_button_art.modulate = Color(0.55, 0.55, 0.55, 0.85)
		return

	if _mission_agree_button_pressed:
		mission_agree_button_art.modulate = Color(0.78, 0.78, 0.78, 0.98)
		return

	if _mission_agree_button_hovered:
		mission_agree_button_art.modulate = Color(1.12, 1.12, 1.12, 1)
		return

	mission_agree_button_art.modulate = Color(1, 1, 1, 1)


func _load_image_from_source(absolute_path: String) -> Image:
	if not FileAccess.file_exists(absolute_path):
		return null

	var image: Image = Image.load_from_file(absolute_path)
	if image != null and not image.is_empty():
		return image

	var file := FileAccess.open(absolute_path, FileAccess.READ)
	if file == null:
		return image

	var buffer: PackedByteArray = file.get_buffer(file.get_length())
	if buffer.size() < 8:
		return image

	var png_signature := PackedByteArray([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
	if buffer.slice(0, 8) == png_signature:
		var png_image := Image.new()
		if png_image.load_png_from_buffer(buffer) == OK:
			return png_image

	var jpg_image := Image.new()
	if jpg_image.load_jpg_from_buffer(buffer) == OK:
		return jpg_image

	return image
