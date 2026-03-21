extends PanelContainer
class_name ChallengePanel

@onready var challenge_title: Label = $CodeMargin/ChallengeRoot/ChallengeHeader/ChallengeTitle
@onready var level_label: Label = $CodeMargin/ChallengeRoot/ChallengeHeader/LevelLabel
@onready var prompt_text: RichTextLabel = $CodeMargin/ChallengeRoot/PromptText
@onready var code_input: TextEdit = $CodeMargin/ChallengeRoot/CodeInput

func initialize(default_code: String) -> void:
	code_input.text = default_code
	show_challenge({})

func get_python_code() -> String:
	return code_input.text

func focus_code_input() -> void:
	code_input.editable = true
	code_input.grab_focus()

func set_code_editable(editable: bool) -> void:
	code_input.editable = editable
	if editable:
		code_input.call_deferred("grab_focus")

func show_challenge(challenge_view: Dictionary) -> void:
	challenge_title.text = str(challenge_view.get("title", "Challenge"))
	level_label.text = str(challenge_view.get("level_label", "Waiting for challenge mode."))
	prompt_text.text = str(challenge_view.get("prompt_body", "No challenge prompt loaded yet."))
	set_code_editable(bool(challenge_view.get("code_editable", false)))
