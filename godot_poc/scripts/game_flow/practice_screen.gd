extends Control
class_name PracticeScreen

signal submit_requested(python_code: String)
signal open_toolbox_requested()
signal back_requested()

@onready var status_label: Label = $Margin/Scroll/Root/StatusLabel
@onready var practice_panel: PracticePanel = $Margin/Scroll/Root/PracticePanel
@onready var feedback_panel: FeedbackPanel = $Margin/Scroll/Root/FeedbackPanel
@onready var submit_button: Button = $Margin/Scroll/Root/Buttons/SubmitButton
@onready var toolbox_button: Button = $Margin/Scroll/Root/Buttons/ToolboxButton
@onready var back_button: Button = $Margin/Scroll/Root/Buttons/BackButton

var _base_can_submit: bool = false
var _base_can_open_toolbox: bool = false
var _base_code_editable: bool = false
var _toolbox_locked: bool = false
var _toolbox_status_message: String = ""

func _ready() -> void:
	submit_button.pressed.connect(_on_submit_button_pressed)
	toolbox_button.pressed.connect(_on_toolbox_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)

func initialize(default_code: String) -> void:
	practice_panel.initialize(default_code)

func show_practice(practice_view: Dictionary) -> void:
	_base_code_editable = bool(practice_view.get("code_editable", false))
	_base_can_open_toolbox = bool(practice_view.get("toolbox_allowed", false))
	practice_panel.show_practice(practice_view)
	_apply_toolbox_lock_state()

func show_feedback(feedback_view: Dictionary) -> void:
	feedback_panel.show_feedback(feedback_view)

func set_status(text: String) -> void:
	status_label.text = text

func set_can_submit(can_submit: bool) -> void:
	_base_can_submit = can_submit
	_apply_toolbox_lock_state()

func set_can_open_toolbox(can_open: bool) -> void:
	_base_can_open_toolbox = can_open
	_apply_toolbox_lock_state()

func set_toolbox_lock(active: bool, status_message: String = "") -> void:
	_toolbox_locked = active
	_toolbox_status_message = status_message
	_apply_toolbox_lock_state()
	if _toolbox_locked:
		status_label.text = _toolbox_status_message if _toolbox_status_message != "" else "Toolbox is active."
	elif status_label.text.begins_with("Toolbox"):
		status_label.text = "Practice flow ready"

func focus_code_editor() -> void:
	if _toolbox_locked:
		return
	practice_panel.focus_code_input()

func _apply_toolbox_lock_state() -> void:
	practice_panel.set_code_editable(_base_code_editable and not _toolbox_locked)
	submit_button.disabled = (not _base_can_submit) or _toolbox_locked
	toolbox_button.visible = _base_can_open_toolbox
	toolbox_button.disabled = (not _base_can_open_toolbox) or _toolbox_locked
	if _toolbox_locked and _toolbox_status_message != "":
		status_label.text = _toolbox_status_message

func _on_submit_button_pressed() -> void:
	status_label.text = "Status: submitting code..."
	var python_code: String = practice_panel.get_python_code()
	submit_requested.emit(python_code)

func _on_toolbox_button_pressed() -> void:
	status_label.text = "Status: opening toolbox..."
	open_toolbox_requested.emit()

func _on_back_button_pressed() -> void:
	status_label.text = "Status: returning to map..."
	back_requested.emit()
