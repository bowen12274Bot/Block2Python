extends Control
class_name DemoScreen

const EMPTY_PREVIEW_TEXT := "No Python preview yet. Add blocks to the workspace, then click Convert Python."
const EMPTY_WORKSPACE_TEXT := "Blockly workspace will attach here when the demo page is active."
const UnlockBlockListRendererScript = preload("res://scripts/shared/unlock_block_list_renderer.gd")
const ACTION_BUTTON_IDLE_MODULATE := Color(0.88, 0.95, 1.0, 0.92)
const ACTION_BUTTON_HOVER_MODULATE := Color(1.0, 1.0, 1.0, 1.0)
const ACTION_BUTTON_PRESSED_MODULATE := Color(0.76, 0.92, 1.0, 1.0)
const ACTION_BUTTON_DISABLED_MODULATE := Color(0.45, 0.52, 0.6, 0.68)
const ACTION_BUTTON_IDLE_SCALE := Vector2.ONE
const ACTION_BUTTON_HOVER_SCALE := Vector2(1.04, 1.04)
const ACTION_BUTTON_PRESSED_SCALE := Vector2(0.96, 0.96)

signal convert_requested()
signal advance_requested()
signal back_requested()

@onready var status_label: Label = $Overlay/TopBar/TopBarRoot/StatusLabel
@onready var title_label: Label = $Overlay/TopBar/TopBarRoot/MissionTitle
@onready var convert_button: Button = $Overlay/TopBar/TopBarRoot/ActionRow/ConvertButton
@onready var continue_button: Button = $Overlay/TopBar/TopBarRoot/ActionRow/ContinueButton
@onready var back_button: Button = $Overlay/TopBar/TopBarRoot/ActionRow/BackButton
@onready var extra_button: Button = $Overlay/TopBar/TopBarRoot/ActionRow/ExtraButton
@onready var convert_icon_art: TextureRect = $Overlay/TopBar/TopBarRoot/ActionRow/ConvertButton/ConvertIconArt
@onready var continue_icon_art: TextureRect = $Overlay/TopBar/TopBarRoot/ActionRow/ContinueButton/ContinueIconArt
@onready var back_icon_art: TextureRect = $Overlay/TopBar/TopBarRoot/ActionRow/BackButton/BackIconArt
@onready var extra_icon_art: TextureRect = $Overlay/TopBar/TopBarRoot/ActionRow/ExtraButton/ExtraIconArt
@onready var prompt_text: RichTextLabel = $Overlay/LeftInfoPanel/InfoScroll/InfoContent/PromptText
@onready var learning_text: RichTextLabel = $Overlay/LeftInfoPanel/InfoScroll/InfoContent/LearningText
@onready var unlock_blocks_container: HFlowContainer = $Overlay/LeftInfoPanel/InfoScroll/InfoContent/UnlockBlocks
@onready var workspace_hint: Label = $Overlay/WorkspacePanel/WorkspaceRoot/WorkspaceSurface/WorkspaceHint
@onready var workspace_surface: PanelContainer = $Overlay/WorkspacePanel/WorkspaceRoot/WorkspaceSurface
@onready var python_preview: CodeEdit = $Overlay/PreviewPanel/PreviewRoot/PythonPreview

var _current_view: Dictionary = {}
var _action_button_icons: Dictionary = {}

func _ready() -> void:
	_setup_action_button_feedback()
	convert_button.pressed.connect(_on_convert_button_pressed)
	continue_button.pressed.connect(_on_continue_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)
	extra_button.disabled = true
	convert_button.tooltip_text = "Convert"
	continue_button.tooltip_text = "Continue"
	back_button.tooltip_text = "Back"
	extra_button.tooltip_text = "Extra"
	python_preview.editable = false
	python_preview.gutters_draw_line_numbers = true
	python_preview.placeholder_text = EMPTY_PREVIEW_TEXT
	python_preview.text = EMPTY_PREVIEW_TEXT
	workspace_hint.text = EMPTY_WORKSPACE_TEXT

func show_demo(demo_view: Dictionary) -> void:
	var previous_level_id: String = str(_current_view.get("current_level_id", ""))
	_current_view = demo_view.duplicate(true)
	title_label.text = str(demo_view.get("title", "Demo Console"))
	prompt_text.text = str(demo_view.get("prompt", "No prompt loaded yet."))
	learning_text.text = str(demo_view.get("learning_markdown", "No learning notes available yet."))
	_populate_unlock_blocks(demo_view)
	var current_level_id: String = str(demo_view.get("current_level_id", ""))
	if current_level_id != previous_level_id:
		clear_python_preview()
	set_workspace_ready(str(demo_view.get("current_level_id", "")) != "")

func show_placeholder(message: String) -> void:
	_current_view = {}
	title_label.text = "Demo Console"
	prompt_text.text = message
	learning_text.text = "Learning notes will appear here."
	_populate_unlock_blocks({})
	clear_python_preview()
	set_workspace_ready(false)

func set_status(text: String) -> void:
	status_label.text = text

func set_can_convert(can_convert: bool) -> void:
	convert_button.disabled = not can_convert
	_refresh_action_button_feedback()

func set_can_advance(can_advance: bool) -> void:
	continue_button.disabled = not can_advance
	_refresh_action_button_feedback()

func set_can_go_back(can_go_back: bool) -> void:
	back_button.disabled = not can_go_back
	_refresh_action_button_feedback()

func set_workspace_ready(active: bool) -> void:
	workspace_hint.visible = not active
	if not active:
		workspace_hint.text = EMPTY_WORKSPACE_TEXT

func set_python_preview(python_code: String) -> void:
	var normalized_code: String = _filtered_preview_code(python_code)
	var next_text := normalized_code if normalized_code != "" else EMPTY_PREVIEW_TEXT
	if python_preview.text == next_text:
		return
	python_preview.text = next_text

func clear_python_preview() -> void:
	if python_preview.text == EMPTY_PREVIEW_TEXT:
		return
	python_preview.text = EMPTY_PREVIEW_TEXT

func _filtered_preview_code(python_code: String) -> String:
	var normalized_code: String = python_code.strip_edges()
	if normalized_code == "":
		return ""

	var lines: PackedStringArray = normalized_code.split("\n")
	var first_content_index: int = 0
	while first_content_index < lines.size():
		var line: String = String(lines[first_content_index]).strip_edges()
		if line == "":
			first_content_index += 1
			continue
		if _is_none_initializer_line(line):
			first_content_index += 1
			continue
		break

	var filtered_lines: PackedStringArray = lines.slice(first_content_index)
	while filtered_lines.size() > 0 and String(filtered_lines[0]).strip_edges() == "":
		filtered_lines.remove_at(0)
	return "\n".join(filtered_lines).strip_edges()

func _is_none_initializer_line(line: String) -> bool:
	var parts: PackedStringArray = line.split("=", false, 1)
	if parts.size() != 2:
		return false
	var variable_name: String = String(parts[0]).strip_edges()
	var assigned_value: String = String(parts[1]).strip_edges()
	if assigned_value != "None":
		return false
	if variable_name == "":
		return false
	var identifier_regex := RegEx.new()
	identifier_regex.compile("^[A-Za-z_][A-Za-z0-9_]*$")
	return identifier_regex.search(variable_name) != null

func current_view() -> Dictionary:
	return _current_view.duplicate(true)

func get_workspace_target_control() -> Control:
	return workspace_surface

func _populate_unlock_blocks(demo_view: Dictionary) -> void:
	UnlockBlockListRendererScript.render(
		unlock_blocks_container,
		demo_view.get("unlock_blocks", []),
		{
			"empty_text": "No new blocks for this demo yet.",
			"empty_modulate": Color(0.72, 0.76, 0.85, 0.84),
			"card_minimum_size": Vector2(0, 52),
			"card_modulate": Color(0.9, 0.96, 1.0, 0.92),
			"margin_left": 12,
			"margin_top": 8,
			"margin_right": 12,
			"margin_bottom": 8,
			"column_separation": 3,
			"title_font_size": 15,
			"title_modulate": Color(0.88, 0.92, 1.0, 0.92),
			"body_font_size": 13,
			"body_modulate": Color(0.72, 0.76, 0.85, 0.9),
		}
	)

func _setup_action_button_feedback() -> void:
	_action_button_icons = {
		convert_button: convert_icon_art,
		continue_button: continue_icon_art,
		back_button: back_icon_art,
		extra_button: extra_icon_art,
	}
	for button: Button in _action_button_icons.keys():
		button.flat = true
		button.mouse_entered.connect(_on_action_button_mouse_entered.bind(button))
		button.mouse_exited.connect(_on_action_button_mouse_exited.bind(button))
		button.button_down.connect(_on_action_button_button_down.bind(button))
		button.button_up.connect(_on_action_button_button_up.bind(button))
	_refresh_action_button_feedback()

func _refresh_action_button_feedback() -> void:
	for button: Button in _action_button_icons.keys():
		var icon: TextureRect = _action_button_icons[button]
		if icon == null:
			continue
		if button.disabled:
			icon.modulate = ACTION_BUTTON_DISABLED_MODULATE
			icon.scale = ACTION_BUTTON_IDLE_SCALE
			continue
		icon.modulate = ACTION_BUTTON_IDLE_MODULATE
		icon.scale = ACTION_BUTTON_IDLE_SCALE

func _on_action_button_mouse_entered(button: Button) -> void:
	var icon: TextureRect = _action_button_icons.get(button)
	if icon == null or button.disabled:
		return
	icon.modulate = ACTION_BUTTON_HOVER_MODULATE
	icon.scale = ACTION_BUTTON_HOVER_SCALE

func _on_action_button_mouse_exited(button: Button) -> void:
	var icon: TextureRect = _action_button_icons.get(button)
	if icon == null:
		return
	if button.disabled:
		icon.modulate = ACTION_BUTTON_DISABLED_MODULATE
		icon.scale = ACTION_BUTTON_IDLE_SCALE
		return
	icon.modulate = ACTION_BUTTON_IDLE_MODULATE
	icon.scale = ACTION_BUTTON_IDLE_SCALE

func _on_action_button_button_down(button: Button) -> void:
	var icon: TextureRect = _action_button_icons.get(button)
	if icon == null or button.disabled:
		return
	icon.modulate = ACTION_BUTTON_PRESSED_MODULATE
	icon.scale = ACTION_BUTTON_PRESSED_SCALE

func _on_action_button_button_up(button: Button) -> void:
	var icon: TextureRect = _action_button_icons.get(button)
	if icon == null or button.disabled:
		return
	if button.get_rect().has_point(button.get_local_mouse_position()):
		icon.modulate = ACTION_BUTTON_HOVER_MODULATE
		icon.scale = ACTION_BUTTON_HOVER_SCALE
		return
	icon.modulate = ACTION_BUTTON_IDLE_MODULATE
	icon.scale = ACTION_BUTTON_IDLE_SCALE

func _on_convert_button_pressed() -> void:
	status_label.text = "Status: converting blocks to Python..."
	convert_requested.emit()

func _on_continue_button_pressed() -> void:
	status_label.text = "Status: continuing demo flow..."
	advance_requested.emit()

func _on_back_button_pressed() -> void:
	status_label.text = "Status: returning to map..."
	back_requested.emit()
