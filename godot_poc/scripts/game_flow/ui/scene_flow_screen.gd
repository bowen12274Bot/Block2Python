extends Control
class_name SceneFlowScreen

const ScenePanelScript = preload("res://scripts/game_flow/ui/scene_panel.gd")
const TASK_BACKGROUND_PATH := "res://art/task/background.png"
const TASK_AGREE_BUTTON_PATH := "res://art/task/agree.png"

signal advance_requested()
signal back_requested()

@onready var scene_panel: ScenePanelScript = $ScenePanel
@onready var advance_button: Button = $Buttons/AdvanceButton
@onready var skip_button: Button = $Buttons/SkipButton
@onready var back_button: Button = $Buttons/BackButton
@onready var mission_overlay: Control = get_node_or_null("MissionOverlay")
@onready var mission_background: TextureRect = get_node_or_null("MissionOverlay/Center/MissionPanel/MissionBackground")
@onready var mission_agree_button_art: TextureRect = get_node_or_null("MissionOverlay/Center/MissionPanel/MissionMargin/MissionRoot/MissionAgreeButton/AgreeButtonArt")
@onready var mission_title_label: Label = get_node_or_null("MissionOverlay/Center/MissionPanel/MissionMargin/MissionRoot/MissionTitle")
@onready var mission_body_label: RichTextLabel = get_node_or_null("MissionOverlay/Center/MissionPanel/MissionMargin/MissionRoot/MissionBody")
@onready var mission_agree_button: Button = get_node_or_null("MissionOverlay/Center/MissionPanel/MissionMargin/MissionRoot/MissionAgreeButton")

var _can_advance: bool = false
var _can_go_back: bool = false
var _mission_brief_visible: bool = false
var _show_mission_brief_on_complete: bool = false
var _mission_brief_title: String = "Mission"
var _mission_brief_text: String = ""


func _ready() -> void:
	_apply_task_background()
	_apply_task_agree_button_art()
	advance_button.pressed.connect(_on_advance_button_pressed)
	skip_button.pressed.connect(_on_skip_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)
	if mission_agree_button != null:
		mission_agree_button.pressed.connect(_on_mission_agree_button_pressed)
	scene_panel.continue_requested.connect(_on_continue_requested)
	_hide_mission_brief()


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


func _mission_brief_body_text() -> String:
	if _mission_brief_text.strip_edges() != "":
		return _mission_brief_text
	return "Read the mission briefing, then press Agree to enter the demo page."


func _apply_task_background() -> void:
	if mission_background == null:
		return

	if ResourceLoader.exists(TASK_BACKGROUND_PATH):
		mission_background.texture = load(TASK_BACKGROUND_PATH)
		return

	var absolute_path: String = ProjectSettings.globalize_path(TASK_BACKGROUND_PATH)
	if not FileAccess.file_exists(absolute_path):
		return

	var image: Image = Image.load_from_file(absolute_path)
	if image == null or image.is_empty():
		return

	mission_background.texture = ImageTexture.create_from_image(image)


func _apply_task_agree_button_art() -> void:
	if mission_agree_button_art == null:
		return

	if ResourceLoader.exists(TASK_AGREE_BUTTON_PATH):
		mission_agree_button_art.texture = load(TASK_AGREE_BUTTON_PATH)
		return

	var absolute_path: String = ProjectSettings.globalize_path(TASK_AGREE_BUTTON_PATH)
	if not FileAccess.file_exists(absolute_path):
		return

	var image: Image = Image.load_from_file(absolute_path)
	if image == null or image.is_empty():
		return

	mission_agree_button_art.texture = ImageTexture.create_from_image(image)
