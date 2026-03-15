extends PanelContainer

@onready var challenge_title: Label = $CodeMargin/ChallengeRoot/ChallengeHeader/ChallengeTitle
@onready var level_label: Label = $CodeMargin/ChallengeRoot/ChallengeHeader/LevelLabel
@onready var code_input: TextEdit = $CodeMargin/ChallengeRoot/CodeInput


func initialize(default_code: String) -> void:
    code_input.text = default_code
    show_challenge({})


func get_python_code() -> String:
    return code_input.text


func show_challenge(challenge_view: Dictionary) -> void:
    challenge_title.text = str(challenge_view.get("title", "Challenge"))
    level_label.text = str(challenge_view.get("level_label", "Waiting for challenge mode."))
    code_input.editable = bool(challenge_view.get("code_editable", false))
