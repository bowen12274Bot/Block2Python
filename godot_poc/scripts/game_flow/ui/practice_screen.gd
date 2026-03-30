extends Control
class_name PracticeScreen

const BATTERY_TEXTURE_PATHS := {
	0: "res://art/practice/battery/battery_000.png",
	10: "res://art/practice/battery/battery_010.png",
	20: "res://art/practice/battery/battery_020.png",
	30: "res://art/practice/battery/battery_030.png",
	40: "res://art/practice/battery/battery_040.png",
	50: "res://art/practice/battery/battery_050.png",
	60: "res://art/practice/battery/battery_060.png",
	70: "res://art/practice/battery/battery_070.png",
	80: "res://art/practice/battery/battery_080.png",
	90: "res://art/practice/battery/battery_090.png",
	100: "res://art/practice/battery/battery_100.png",
}
const TOOLBOX_BUTTON_IDLE_TEXTURE_PATH := "res://art/practice/buttons/toolbox_button_idle.png"
const TOOLBOX_BUTTON_ACTIVE_TEXTURE_PATH := "res://art/practice/buttons/toolbox_button_active.png"

signal run_requested(python_code: String)
signal submit_requested(python_code: String)
signal next_requested()
signal open_toolbox_requested()
signal toolbox_confirmation_accepted()
signal back_requested()

@onready var status_label: Label = $Overlay/TopBar/TopBarMargin/TopBarRoot/StatusLabel
@onready var mission_title_label: Label = $Overlay/TopBar/TopBarMargin/TopBarRoot/TopRow/TitleRow/MissionTitle
@onready var progress_label: Label = $Overlay/TopBar/TopBarMargin/TopBarRoot/TopRow/TitleRow/ProgressLabel
@onready var run_button: Button = $Overlay/TopBar/TopBarMargin/TopBarRoot/TopRow/ActionRow/RunButton
@onready var submit_button: Button = $Overlay/TopBar/TopBarMargin/TopBarRoot/TopRow/ActionRow/SubmitButton
@onready var next_button: Button = $Overlay/TopBar/TopBarMargin/TopBarRoot/TopRow/ActionRow/NextButton
@onready var back_button: Button = $Overlay/TopBar/TopBarMargin/TopBarRoot/TopRow/ActionRow/BackButton
@onready var mission_text: RichTextLabel = $Overlay/MissionPanel/MissionMargin/MissionRoot/MissionText
@onready var battery_panel_art: TextureRect = $Overlay/BatteryPanel/BatteryPanelArt
@onready var battery_header_label: Label = get_node_or_null("Overlay/BatteryPanel/BatteryMargin/BatteryRoot/BatteryHeader")
@onready var battery_percent_label: Label = get_node_or_null("Overlay/BatteryPanel/BatteryMargin/BatteryRoot/BatteryPercent")
@onready var battery_threshold_label: Label = get_node_or_null("Overlay/BatteryPanel/BatteryMargin/BatteryRoot/BatteryThreshold")
@onready var battery_bar: ProgressBar = get_node_or_null("Overlay/BatteryPanel/BatteryMargin/BatteryRoot/BatteryBar")
@onready var practice_panel: PracticePanel = $Overlay/PracticePanel
@onready var feedback_panel: FeedbackPanel = $Overlay/OutputPanel
@onready var assistant_log: RichTextLabel = $Overlay/AssistantPanel/AssistantMargin/AssistantRoot/AssistantLog
@onready var assistant_input: LineEdit = $Overlay/AssistantPanel/AssistantMargin/AssistantRoot/AssistantInput
@onready var toolbox_button: Button = $Overlay/ToolkitPanel/ToolboxButton
@onready var toolbox_panel_art: TextureRect = $Overlay/ToolkitPanel/ToolboxPanelArt

var _toolbox_confirmation_dialog: ConfirmationDialog
var _base_can_run: bool = false
var _base_can_submit: bool = false
var _base_can_next: bool = false
var _base_can_open_toolbox: bool = false
var _base_code_editable: bool = false
var _toolbox_locked: bool = false
var _current_view: Dictionary = {}
var _toolbox_status_message: String = ""
var _battery_textures: Dictionary = {}
var _toolbox_button_idle_texture: Texture2D
var _toolbox_button_active_texture: Texture2D

func _ready() -> void:
	_load_art_textures()
	run_button.pressed.connect(_on_run_button_pressed)
	submit_button.pressed.connect(_on_submit_button_pressed)
	next_button.pressed.connect(_on_next_button_pressed)
	toolbox_button.pressed.connect(_on_toolbox_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)
	assistant_input.editable = false
	toolbox_button.text = "" if _toolbox_button_idle_texture != null or _toolbox_button_active_texture != null else "TOOLBOX"
	_toolbox_confirmation_dialog = ConfirmationDialog.new()
	_toolbox_confirmation_dialog.title = "Tool Kit Warning"
	_toolbox_confirmation_dialog.confirmed.connect(_on_toolbox_confirmation_confirmed)
	add_child(_toolbox_confirmation_dialog)
	_update_battery_visual(0)
	_update_toolbox_visual()

func initialize(default_code: String) -> void:
	practice_panel.initialize(default_code)

func show_practice(practice_view: Dictionary) -> void:
	_current_view = practice_view.duplicate(true)
	_base_code_editable = bool(practice_view.get("code_editable", false))
	_base_can_open_toolbox = bool(practice_view.get("toolbox_allowed", false))
	_base_can_run = bool(practice_view.get("can_run", false))
	_base_can_submit = bool(practice_view.get("can_submit", false))
	_base_can_next = bool(practice_view.get("can_next", false))
	mission_title_label.text = str(practice_view.get("title", "Practice"))
	progress_label.text = str(practice_view.get("progress_label", "Progress: --"))
	mission_text.text = str(practice_view.get("mission_text", "No mission loaded yet."))
	var battery_percent := int(practice_view.get("battery_percent", 0))
	if battery_bar != null:
		battery_bar.value = float(battery_percent)
	if battery_percent_label != null:
		battery_percent_label.text = "%s%%" % str(battery_percent)
	if battery_threshold_label != null:
		battery_threshold_label.text = "Threshold: %s%%" % str(practice_view.get("battery_threshold_percent", 80))
	assistant_log.text = str(practice_view.get("assistant_chat_text", "Byte: Practice assistant is standing by."))
	_update_battery_visual(battery_percent)
	practice_panel.show_practice(practice_view)
	_apply_toolbox_lock_state()

func current_view() -> Dictionary:
	return _current_view.duplicate(true)

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

func prompt_toolbox_confirmation(penalty_percent: int) -> void:
	_toolbox_confirmation_dialog.dialog_text = "Opening Tool Kit for this level will reduce the battery reward to %d%%. Continue?" % penalty_percent
	_toolbox_confirmation_dialog.popup_centered()

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
	if not is_inside_tree():
		return
	practice_panel.focus_code_input()

func _apply_toolbox_lock_state() -> void:
	practice_panel.set_code_editable(_base_code_editable and not _toolbox_locked)
	run_button.disabled = not _base_can_run
	submit_button.disabled = (not _base_can_submit) or _toolbox_locked
	next_button.disabled = (not _base_can_next) or _toolbox_locked
	toolbox_button.disabled = not _base_can_open_toolbox
	_update_toolbox_visual()
	if _toolbox_locked and _toolbox_status_message != "":
		status_label.text = _toolbox_status_message

func _on_run_button_pressed() -> void:
	status_label.text = "Status: running toolkit..." if _toolbox_locked else "Status: running code..."
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
	status_label.text = "Status: closing toolkit..." if _toolbox_locked else "Status: opening toolkit..."
	open_toolbox_requested.emit()

func _on_toolbox_confirmation_confirmed() -> void:
	status_label.text = "Status: confirming toolbox penalty..."
	toolbox_confirmation_accepted.emit()

func _on_back_button_pressed() -> void:
	status_label.text = "Status: returning to map..."
	back_requested.emit()

func _load_art_textures() -> void:
	for percent in BATTERY_TEXTURE_PATHS.keys():
		var texture := load(BATTERY_TEXTURE_PATHS[percent]) as Texture2D
		if texture != null:
			_battery_textures[percent] = texture
	_toolbox_button_idle_texture = load(TOOLBOX_BUTTON_IDLE_TEXTURE_PATH) as Texture2D
	_toolbox_button_active_texture = load(TOOLBOX_BUTTON_ACTIVE_TEXTURE_PATH) as Texture2D

func _update_battery_visual(battery_percent: int) -> void:
	var normalized_percent := clampi(int(round(float(battery_percent) / 10.0) * 10.0), 0, 100)
	var texture := _battery_textures.get(normalized_percent, null) as Texture2D
	var has_texture := texture != null
	battery_panel_art.texture = texture
	if battery_header_label != null:
		battery_header_label.visible = not has_texture
	if battery_percent_label != null:
		battery_percent_label.visible = not has_texture
	if battery_bar != null:
		battery_bar.visible = not has_texture

func _update_toolbox_visual() -> void:
	var texture := _toolbox_button_active_texture if _toolbox_locked else _toolbox_button_idle_texture
	if toolbox_panel_art != null and texture != null:
		toolbox_panel_art.texture = texture
		toolbox_button.text = ""
	elif toolbox_button != null:
		toolbox_button.text = "CLOSE" if _toolbox_locked else "TOOLBOX"
