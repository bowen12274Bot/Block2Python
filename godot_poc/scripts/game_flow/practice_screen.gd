extends Control
class_name PracticeScreen

signal run_requested(python_code: String)
signal submit_requested(python_code: String)
signal next_requested()
signal open_toolbox_requested()
signal back_requested()

@onready var status_label: Label = $Margin/Root/TopBar/TopBarMargin/TopBarRoot/StatusLabel
@onready var mission_title_label: Label = $Margin/Root/TopBar/TopBarMargin/TopBarRoot/TitleRow/MissionTitle
@onready var progress_label: Label = $Margin/Root/TopBar/TopBarMargin/TopBarRoot/TitleRow/ProgressLabel
@onready var run_button: Button = $Margin/Root/TopBar/TopBarMargin/TopBarRoot/ActionRow/RunButton
@onready var submit_button: Button = $Margin/Root/TopBar/TopBarMargin/TopBarRoot/ActionRow/SubmitButton
@onready var next_button: Button = $Margin/Root/TopBar/TopBarMargin/TopBarRoot/ActionRow/NextButton
@onready var back_button: Button = $Margin/Root/TopBar/TopBarMargin/TopBarRoot/ActionRow/BackButton
@onready var mission_text: RichTextLabel = $Margin/Root/Body/LeftColumn/MissionPanel/MissionMargin/MissionRoot/MissionText
@onready var battery_percent_label: Label = $Margin/Root/Body/LeftColumn/BatteryPanel/BatteryMargin/BatteryRoot/BatteryPercent
@onready var battery_threshold_label: Label = $Margin/Root/Body/LeftColumn/BatteryPanel/BatteryMargin/BatteryRoot/BatteryThreshold
@onready var battery_bar: ProgressBar = $Margin/Root/Body/LeftColumn/BatteryPanel/BatteryMargin/BatteryRoot/BatteryBar
@onready var practice_panel: PracticePanel = $Margin/Root/Body/CenterColumn/PracticePanel
@onready var feedback_panel: FeedbackPanel = $Margin/Root/Body/CenterColumn/OutputPanel
@onready var assistant_log: RichTextLabel = $Margin/Root/Body/RightColumn/AssistantPanel/AssistantMargin/AssistantRoot/AssistantLog
@onready var assistant_input: LineEdit = $Margin/Root/Body/RightColumn/AssistantPanel/AssistantMargin/AssistantRoot/AssistantInput
@onready var toolkit_hint: RichTextLabel = $Margin/Root/Body/RightColumn/ToolkitPanel/ToolkitMargin/ToolkitRoot/ToolkitHint
@onready var toolbox_button: Button = $Margin/Root/Body/RightColumn/ToolkitPanel/ToolkitMargin/ToolkitRoot/ToolboxButton

var _base_can_run: bool = false
var _base_can_submit: bool = false
var _base_can_next: bool = false
var _base_can_open_toolbox: bool = false
var _base_code_editable: bool = false
var _toolbox_locked: bool = false
var _toolbox_status_message: String = ""

func _ready() -> void:
	run_button.pressed.connect(_on_run_button_pressed)
	submit_button.pressed.connect(_on_submit_button_pressed)
	next_button.pressed.connect(_on_next_button_pressed)
	toolbox_button.pressed.connect(_on_toolbox_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)
	assistant_input.editable = false

func initialize(default_code: String) -> void:
	practice_panel.initialize(default_code)

func show_practice(practice_view: Dictionary) -> void:
	_base_code_editable = bool(practice_view.get("code_editable", false))
	_base_can_open_toolbox = bool(practice_view.get("toolbox_allowed", false))
	_base_can_run = bool(practice_view.get("can_run", false))
	_base_can_submit = bool(practice_view.get("can_submit", false))
	_base_can_next = bool(practice_view.get("can_next", false))
	mission_title_label.text = str(practice_view.get("title", "Practice"))
	progress_label.text = str(practice_view.get("progress_label", "Progress: --"))
	mission_text.text = str(practice_view.get("mission_text", "No mission loaded yet."))
	battery_bar.value = float(practice_view.get("battery_percent", 0))
	battery_percent_label.text = "Battery: %s%%" % str(practice_view.get("battery_percent", 0))
	battery_threshold_label.text = "Threshold: %s%%" % str(practice_view.get("battery_threshold_percent", 80))
	assistant_log.text = str(practice_view.get("assistant_chat_text", "Byte: Practice assistant is standing by."))
	toolkit_hint.text = str(practice_view.get("toolkit_hint", "Open the toolkit when you need help exploring a block-based solution."))
	practice_panel.show_practice(practice_view)
	_apply_toolbox_lock_state()

func show_feedback(feedback_view: Dictionary) -> void:
	feedback_panel.show_feedback(feedback_view)

func set_status(text: String) -> void:
	status_label.text = text

func set_can_run(can_run: bool) -> void:
	_base_can_run = can_run
	_apply_toolbox_lock_state()

func set_can_submit(can_submit: bool) -> void:
	_base_can_submit = can_submit
	_apply_toolbox_lock_state()

func set_can_next(can_next: bool) -> void:
	_base_can_next = can_next
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
	run_button.disabled = (not _base_can_run) or _toolbox_locked
	submit_button.disabled = (not _base_can_submit) or _toolbox_locked
	next_button.disabled = (not _base_can_next) or _toolbox_locked
	toolbox_button.disabled = (not _base_can_open_toolbox) or _toolbox_locked
	if _toolbox_locked and _toolbox_status_message != "":
		status_label.text = _toolbox_status_message

func _on_run_button_pressed() -> void:
	status_label.text = "Status: running code..."
	var python_code: String = practice_panel.get_python_code()
	run_requested.emit(python_code)

func _on_submit_button_pressed() -> void:
	status_label.text = "Status: submitting code..."
	var python_code: String = practice_panel.get_python_code()
	submit_requested.emit(python_code)

func _on_next_button_pressed() -> void:
	status_label.text = "Status: moving to next level..."
	next_requested.emit()

func _on_toolbox_button_pressed() -> void:
	status_label.text = "Status: opening toolkit..."
	open_toolbox_requested.emit()

func _on_back_button_pressed() -> void:
	status_label.text = "Status: returning to map..."
	back_requested.emit()
