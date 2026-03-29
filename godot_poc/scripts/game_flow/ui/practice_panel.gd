extends PanelContainer
class_name PracticePanel

const TOOLBOX_ATTACH_PADDING := Rect2i(0, 0, 0, 0)
const WindowAlignmentHelperScript = preload("res://scripts/bridge/window_alignment.gd")

@onready var editor_title: Label = $Margin/Root/Header/EditorTitle
@onready var code_input: TextEdit = $Margin/Root/CodeInput

func initialize(default_code: String) -> void:
	code_input.text = default_code
	show_practice({})

func get_python_code() -> String:
	return code_input.text

func focus_code_input() -> void:
	code_input.editable = true
	code_input.grab_focus()

func set_code_editable(editable: bool) -> void:
	code_input.editable = editable
	if editable:
		code_input.call_deferred("grab_focus")

func get_toolbox_target_control() -> Control:
	return code_input

func get_editor_screen_rect() -> Dictionary:
	return WindowAlignmentHelperScript.build_control_client_rect(get_toolbox_target_control(), TOOLBOX_ATTACH_PADDING)

func show_practice(practice_view: Dictionary) -> void:
	var current_level_id: String = str(practice_view.get("current_level_id", "level"))
	editor_title.text = "EDITOR: %s.py" % current_level_id.replace("-", "_")
	set_code_editable(bool(practice_view.get("code_editable", false)))
