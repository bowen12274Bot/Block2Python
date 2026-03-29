extends Control
class_name DemoScreen

const EMPTY_PREVIEW_TEXT := "No Python preview yet. Add blocks to the workspace, then click Convert Python."
const EMPTY_WORKSPACE_TEXT := "Blockly workspace will attach here when the demo page is active."
const UnlockBlockListRendererScript = preload("res://scripts/shared/unlock_block_list_renderer.gd")

signal convert_requested()
signal advance_requested()
signal back_requested()

@onready var status_label: Label = $Margin/Root/TopBar/TopBarMargin/TopBarRoot/StatusLabel
@onready var title_label: Label = $Margin/Root/TopBar/TopBarMargin/TopBarRoot/TitleRow/MissionTitle
@onready var convert_button: Button = $Margin/Root/TopBar/TopBarMargin/TopBarRoot/TitleRow/ActionRow/ConvertButton
@onready var continue_button: Button = $Margin/Root/TopBar/TopBarMargin/TopBarRoot/TitleRow/ActionRow/ContinueButton
@onready var back_button: Button = $Margin/Root/TopBar/TopBarMargin/TopBarRoot/TitleRow/ActionRow/BackButton
@onready var prompt_text: RichTextLabel = $Margin/Root/Body/LeftColumn/LearningPanel/LearningMargin/LearningRoot/PromptText
@onready var learning_text: RichTextLabel = $Margin/Root/Body/LeftColumn/LearningPanel/LearningMargin/LearningRoot/LearningText
@onready var unlock_blocks_container: HFlowContainer = $Margin/Root/Body/LeftColumn/LearningPanel/LearningMargin/LearningRoot/UnlockBlocks
@onready var workspace_hint: Label = $Margin/Root/Body/RightColumn/WorkspacePanel/WorkspaceMargin/WorkspaceRoot/WorkspaceSurface/WorkspaceHint
@onready var workspace_surface: PanelContainer = $Margin/Root/Body/RightColumn/WorkspacePanel/WorkspaceMargin/WorkspaceRoot/WorkspaceSurface
@onready var python_preview: CodeEdit = $Margin/Root/Body/RightColumn/PreviewPanel/PreviewMargin/PreviewRoot/PythonPreview

func _ready() -> void:
	convert_button.pressed.connect(_on_convert_button_pressed)
	continue_button.pressed.connect(_on_continue_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)
	python_preview.editable = false
	python_preview.gutters_draw_line_numbers = true
	python_preview.placeholder_text = EMPTY_PREVIEW_TEXT
	python_preview.text = EMPTY_PREVIEW_TEXT
	workspace_hint.text = EMPTY_WORKSPACE_TEXT

func show_demo(demo_view: Dictionary) -> void:
	title_label.text = str(demo_view.get("title", "Demo Console"))
	prompt_text.text = str(demo_view.get("prompt", "No prompt loaded yet."))
	learning_text.text = str(demo_view.get("learning_markdown", "No learning notes available yet."))
	_populate_unlock_blocks(demo_view)
	clear_python_preview()
	set_workspace_ready(str(demo_view.get("current_level_id", "")) != "")

func show_placeholder(message: String) -> void:
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

func set_can_advance(can_advance: bool) -> void:
	continue_button.disabled = not can_advance

func set_can_go_back(can_go_back: bool) -> void:
	back_button.disabled = not can_go_back

func set_workspace_ready(active: bool) -> void:
	workspace_hint.visible = not active
	if not active:
		workspace_hint.text = EMPTY_WORKSPACE_TEXT

func set_python_preview(python_code: String) -> void:
	var normalized_code: String = _filtered_preview_code(python_code)
	python_preview.text = normalized_code if normalized_code != "" else EMPTY_PREVIEW_TEXT

func clear_python_preview() -> void:
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

func _on_convert_button_pressed() -> void:
	status_label.text = "Status: converting blocks to Python..."
	convert_requested.emit()

func _on_continue_button_pressed() -> void:
	status_label.text = "Status: continuing demo flow..."
	advance_requested.emit()

func _on_back_button_pressed() -> void:
	status_label.text = "Status: returning to map..."
	back_requested.emit()
