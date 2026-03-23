extends Control
class_name ChallengeScreen

const ChallengePanelScript = preload("res://scripts/game_flow/challenge_panel.gd")
const FeedbackPanelScript = preload("res://scripts/game_flow/feedback_panel.gd")

signal submit_requested(python_code: String)
signal back_requested()

@onready var status_label: Label = $Margin/Scroll/Root/StatusLabel
@onready var challenge_panel: ChallengePanelScript = $Margin/Scroll/Root/ChallengePanel
@onready var feedback_panel: FeedbackPanelScript = $Margin/Scroll/Root/FeedbackPanel
@onready var submit_button: Button = $Margin/Scroll/Root/Buttons/SubmitButton
@onready var back_button: Button = $Margin/Scroll/Root/Buttons/BackButton


func _ready() -> void:
	submit_button.pressed.connect(_on_submit_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)


func initialize(default_code: String) -> void:
	challenge_panel.initialize(default_code)


func show_challenge(challenge_view: Dictionary) -> void:
	challenge_panel.show_challenge(challenge_view)


func show_feedback(feedback_view: Dictionary) -> void:
	feedback_panel.show_feedback(feedback_view)


func set_status(text: String) -> void:
	status_label.text = text


func set_can_submit(can_submit: bool) -> void:
	submit_button.disabled = not can_submit


func _on_submit_button_pressed() -> void:
	status_label.text = "Status: submitting code..."
	var python_code: String = challenge_panel.get_python_code()
	submit_requested.emit(python_code)


func _on_back_button_pressed() -> void:
	status_label.text = "Status: returning to map..."
	back_requested.emit()
