extends PanelContainer
class_name PracticePanel

@onready var practice_title: Label = $CodeMargin/PracticeRoot/PracticeHeader/PracticeTitle
@onready var level_label: Label = $CodeMargin/PracticeRoot/PracticeHeader/LevelLabel
@onready var prompt_text: RichTextLabel = $CodeMargin/PracticeRoot/PromptText
@onready var code_input: TextEdit = $CodeMargin/PracticeRoot/CodeInput

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

func show_practice(practice_view: Dictionary) -> void:
	practice_title.text = str(practice_view.get("title", "Practice"))
	level_label.text = str(practice_view.get("level_label", "Waiting for practice mode."))
	prompt_text.text = str(practice_view.get("prompt_body", "No practice prompt loaded yet."))
	set_code_editable(bool(practice_view.get("code_editable", false)))
