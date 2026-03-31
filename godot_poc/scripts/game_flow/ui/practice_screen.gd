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
const DEFAULT_OPENAI_ENDPOINT := "https://api.openai.com/v1/chat/completions"
const DEFAULT_OPENAI_MODEL := "gpt-4o-mini"
const DEFAULT_OPENAI_TIMEOUT_SEC := 30.0
const TUTOR_REPLY_TYPE_COLOR_DEFAULT := Color(0.72549, 0.756863, 0.854902, 0.84)
const TUTOR_REPLY_TYPE_COLOR_HINT := Color(0.572549, 0.862745, 0.705882, 0.96)
const TUTOR_REPLY_TYPE_COLOR_CONCEPT := Color(0.564706, 0.760784, 0.94902, 0.96)
const TUTOR_REPLY_TYPE_COLOR_DEBUG := Color(0.968627, 0.788235, 0.462745, 0.96)
const TUTOR_REPLY_TYPE_COLOR_REFUSAL := Color(0.952941, 0.572549, 0.572549, 0.96)
const TUTOR_REPLY_TYPE_COLOR_ERROR := Color(0.972549, 0.501961, 0.501961, 0.96)
const ACTION_BUTTON_IDLE_MODULATE := Color(0.88, 0.95, 1.0, 0.92)
const ACTION_BUTTON_HOVER_MODULATE := Color(1.0, 1.0, 1.0, 1.0)
const ACTION_BUTTON_PRESSED_MODULATE := Color(0.76, 0.92, 1.0, 1.0)
const ACTION_BUTTON_DISABLED_MODULATE := Color(0.45, 0.52, 0.6, 0.68)
const ACTION_BUTTON_IDLE_SCALE := Vector2.ONE
const ACTION_BUTTON_HOVER_SCALE := Vector2(1.04, 1.04)
const ACTION_BUTTON_PRESSED_SCALE := Vector2(0.96, 0.96)
const TOOLBOX_IDLE_PYTHON_MODULATE := Color(1.0, 1.0, 1.0, 1.0)
const TOOLBOX_HOVER_PYTHON_MODULATE := Color(0.86, 0.9, 0.96, 0.92)
const TOOLBOX_IDLE_TOOLBOX_MODULATE := Color(1.0, 1.0, 1.0, 1.0)
const TOOLBOX_HOVER_TOOLBOX_MODULATE := Color(1.06, 1.08, 1.1, 1.0)
const TOOLBOX_DISABLED_MODULATE := Color(0.42, 0.48, 0.56, 0.6)

signal run_requested(python_code: String)
signal submit_requested(python_code: String)
signal next_requested()
signal open_toolbox_requested()
signal tutor_requested(question: String, provider: String, provider_options: Dictionary)
signal tutor_cancel_requested()
signal tutor_config_saved(config: Dictionary)
signal toolbox_confirmation_accepted()
signal back_requested()

@onready var status_label: Label = $Overlay/TopBar/TopBarMargin/TopBarRoot/StatusLabel
@onready var mission_title_label: Label = $Overlay/TopBar/TopBarMargin/TopBarRoot/TopRow/TitleRow/MissionTitle
@onready var progress_label: Label = $Overlay/TopBar/TopBarMargin/TopBarRoot/TopRow/TitleRow/ProgressLabel
@onready var run_button: Button = $Overlay/TopBar/TopBarMargin/TopBarRoot/TopRow/ActionRow/RunButton
@onready var submit_button: Button = $Overlay/TopBar/TopBarMargin/TopBarRoot/TopRow/ActionRow/SubmitButton
@onready var next_button: Button = $Overlay/TopBar/TopBarMargin/TopBarRoot/TopRow/ActionRow/NextButton
@onready var back_button: Button = $Overlay/TopBar/TopBarMargin/TopBarRoot/TopRow/ActionRow/BackButton
@onready var extra_button: Button = $Overlay/TopBar/TopBarMargin/TopBarRoot/TopRow/ActionRow/ExtraButton
@onready var mission_text: RichTextLabel = $Overlay/MissionPanel/MissionMargin/MissionRoot/MissionText
@onready var run_icon_art: TextureRect = $Overlay/TopBar/TopBarMargin/TopBarRoot/TopRow/ActionRow/RunButton/RunIconArt
@onready var submit_icon_art: TextureRect = $Overlay/TopBar/TopBarMargin/TopBarRoot/TopRow/ActionRow/SubmitButton/SubmitIconArt
@onready var next_icon_art: TextureRect = $Overlay/TopBar/TopBarMargin/TopBarRoot/TopRow/ActionRow/NextButton/NextIconArt
@onready var map_icon_art: TextureRect = $Overlay/TopBar/TopBarMargin/TopBarRoot/TopRow/ActionRow/BackButton/MapIconArt
@onready var extra_icon_art: TextureRect = $Overlay/TopBar/TopBarMargin/TopBarRoot/TopRow/ActionRow/ExtraButton/ExtraIconArt
@onready var battery_panel_art: TextureRect = $Overlay/BatteryPanel/BatteryPanelArt
@onready var battery_header_label: Label = get_node_or_null("Overlay/BatteryPanel/BatteryMargin/BatteryRoot/BatteryHeader")
@onready var battery_percent_label: Label = get_node_or_null("Overlay/BatteryPanel/BatteryMargin/BatteryRoot/BatteryPercent")
@onready var battery_threshold_label: Label = get_node_or_null("Overlay/BatteryPanel/BatteryMargin/BatteryRoot/BatteryThreshold")
@onready var battery_bar: ProgressBar = get_node_or_null("Overlay/BatteryPanel/BatteryMargin/BatteryRoot/BatteryBar")
@onready var practice_panel: PracticePanel = $Overlay/PracticePanel
@onready var feedback_panel: FeedbackPanel = $Overlay/OutputPanel
@onready var assistant_log: RichTextLabel = $Overlay/AssistantPanel/AssistantMargin/AssistantRoot/AssistantLog
@onready var assistant_input: LineEdit = $Overlay/AssistantPanel/AssistantMargin/AssistantRoot/AssistantInput
@onready var provider_option: OptionButton = $Overlay/AssistantPanel/AssistantMargin/AssistantRoot/ConfigRow/ProviderOption
@onready var assistant_api_key_input: LineEdit = $Overlay/AssistantPanel/AssistantMargin/AssistantRoot/ConfigRow/ApiKeyInput
@onready var save_tutor_config_button: Button = $Overlay/AssistantPanel/AssistantMargin/AssistantRoot/ConfigRow/SaveTutorConfigButton
@onready var ask_tutor_button: Button = $Overlay/AssistantPanel/AssistantMargin/AssistantRoot/ActionRow/AskTutorButton
@onready var cancel_tutor_button: Button = $Overlay/AssistantPanel/AssistantMargin/AssistantRoot/ActionRow/CancelTutorButton
@onready var tutor_reply_type_label: Label = $Overlay/AssistantPanel/AssistantMargin/AssistantRoot/TutorStats/ReplyTypeLabel
@onready var tutor_request_cost_label: Label = $Overlay/AssistantPanel/AssistantMargin/AssistantRoot/TutorStats/RequestCostLabel
@onready var tutor_total_cost_label: Label = $Overlay/AssistantPanel/AssistantMargin/AssistantRoot/TutorStats/TotalCostLabel
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
var _toolbox_button_hovered: bool = false
var _action_button_icons: Dictionary = {}
var _tutor_config: Dictionary = {
	"provider": "template",
	"endpoint_url": DEFAULT_OPENAI_ENDPOINT,
	"model": DEFAULT_OPENAI_MODEL,
	"api_key": "",
	"timeout_sec": DEFAULT_OPENAI_TIMEOUT_SEC,
}
var _tutor_pending: bool = false
var _total_tutor_cost: float = 0.0

func _ready() -> void:
	_load_art_textures()
	_setup_action_button_feedback()
	run_button.pressed.connect(_on_run_button_pressed)
	submit_button.pressed.connect(_on_submit_button_pressed)
	next_button.pressed.connect(_on_next_button_pressed)
	toolbox_button.pressed.connect(_on_toolbox_button_pressed)
	toolbox_button.mouse_entered.connect(_on_toolbox_button_mouse_entered)
	toolbox_button.mouse_exited.connect(_on_toolbox_button_mouse_exited)
	back_button.pressed.connect(_on_back_button_pressed)
	extra_button.disabled = true
	run_button.tooltip_text = "Run"
	submit_button.tooltip_text = "Submit"
	next_button.tooltip_text = "Next"
	back_button.tooltip_text = "Back to Map"
	extra_button.tooltip_text = "Extra"
	assistant_input.text_submitted.connect(_on_assistant_input_submitted)
	ask_tutor_button.pressed.connect(_on_ask_tutor_button_pressed)
	cancel_tutor_button.pressed.connect(_on_cancel_tutor_button_pressed)
	save_tutor_config_button.pressed.connect(_on_save_tutor_config_button_pressed)
	provider_option.item_selected.connect(_on_provider_option_selected)
	toolbox_button.text = "" if _toolbox_button_idle_texture != null or _toolbox_button_active_texture != null else "TOOLBOX"
	_toolbox_confirmation_dialog = ConfirmationDialog.new()
	_toolbox_confirmation_dialog.title = "Tool Kit Warning"
	_toolbox_confirmation_dialog.confirmed.connect(_on_toolbox_confirmation_confirmed)
	add_child(_toolbox_confirmation_dialog)
	_setup_provider_options()
	_reset_tutor_stats()
	_update_battery_visual(0)
	_update_toolbox_visual()
	_refresh_tutor_input_state()

func initialize(default_code: String) -> void:
	practice_panel.initialize(default_code)

func show_practice(practice_view: Dictionary) -> void:
	_current_view = practice_view.duplicate(true)
	_base_code_editable = bool(practice_view.get("code_editable", false))
	_base_can_open_toolbox = bool(practice_view.get("toolbox_allowed", false))
	_base_can_run = bool(practice_view.get("can_run", false))
	_base_can_submit = bool(practice_view.get("can_submit", false))
	_base_can_next = bool(practice_view.get("can_next", false))
	var level_title := str(practice_view.get("current_level_title", practice_view.get("level_title", "")))
	mission_title_label.text = level_title if level_title != "" else "Practice"
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
	assistant_input.placeholder_text = (
		"Ask Byte about this level and press Enter..."
		if str(practice_view.get("current_level_id", "")) != ""
		else "Tutor is available after entering a level."
	)
	_update_battery_visual(battery_percent)
	practice_panel.show_practice(practice_view)
	_apply_toolbox_lock_state()
	_refresh_tutor_input_state()

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

func current_python_code() -> String:
	return practice_panel.get_python_code()

func set_tutor_config(config: Dictionary) -> void:
	_tutor_config = {
		"provider": str(config.get("provider", "template")).strip_edges().to_lower(),
		"endpoint_url": str(config.get("endpoint_url", DEFAULT_OPENAI_ENDPOINT)),
		"model": str(config.get("model", DEFAULT_OPENAI_MODEL)),
		"api_key": str(config.get("api_key", "")),
		"timeout_sec": float(config.get("timeout_sec", DEFAULT_OPENAI_TIMEOUT_SEC)),
	}
	_select_provider(str(_tutor_config.get("provider", "template")))
	assistant_api_key_input.text = str(_tutor_config.get("api_key", ""))
	_refresh_tutor_input_state()

func show_tutor_reply(reply_type: String, content: String, metadata: Dictionary = {}) -> void:
	_tutor_pending = false
	_refresh_tutor_input_state()
	_append_assistant_entry(_reply_type_label(reply_type), content)
	_apply_reply_type_visual(reply_type)
	_update_cost_labels(metadata)
	var provider_label: String = str(metadata.get("provider", "")).strip_edges()
	if provider_label != "":
		status_label.text = "Status: tutor reply received (%s)" % provider_label
	else:
		status_label.text = "Status: tutor reply received"

func show_tutor_error(message: String) -> void:
	_tutor_pending = false
	_refresh_tutor_input_state()
	_append_assistant_entry("System", message)
	_apply_reply_type_visual("error")
	status_label.text = "Status: tutor request failed"

func set_tutor_pending(pending: bool) -> void:
	_tutor_pending = pending
	_refresh_tutor_input_state()

func _apply_toolbox_lock_state() -> void:
	practice_panel.set_code_editable(_base_code_editable and not _toolbox_locked)
	run_button.disabled = not _base_can_run
	submit_button.disabled = (not _base_can_submit) or _toolbox_locked
	next_button.disabled = (not _base_can_next) or _toolbox_locked
	toolbox_button.disabled = not _base_can_open_toolbox
	_update_toolbox_visual()
	_refresh_action_button_feedback()
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

func _on_assistant_input_submitted(text: String) -> void:
	_submit_tutor_question(text)

func _on_ask_tutor_button_pressed() -> void:
	_submit_tutor_question(assistant_input.text)

func _on_cancel_tutor_button_pressed() -> void:
	if not _tutor_pending:
		return
	_tutor_pending = false
	_refresh_tutor_input_state()
	status_label.text = "Status: cancelling tutor request..."
	tutor_cancel_requested.emit()

func _on_save_tutor_config_button_pressed() -> void:
	_tutor_config["provider"] = _selected_provider()
	_tutor_config["api_key"] = assistant_api_key_input.text.strip_edges()
	tutor_config_saved.emit(_tutor_config.duplicate(true))
	status_label.text = "Status: tutor settings saved locally."

func _on_provider_option_selected(_index: int) -> void:
	_refresh_tutor_input_state()

func _submit_tutor_question(text: String) -> void:
	var question: String = text.strip_edges()
	if question == "":
		status_label.text = "Status: enter a tutor question first."
		return
	if str(_current_view.get("current_level_id", "")) == "":
		status_label.text = "Status: tutor is unavailable before entering a level."
		return

	var provider: String = str(_tutor_config.get("provider", "template"))
	_tutor_config["provider"] = provider
	_tutor_config["api_key"] = assistant_api_key_input.text.strip_edges()
	var provider_options: Dictionary = {}
	if provider == "openai_compatible":
		if _tutor_config["api_key"] == "":
			status_label.text = "Status: API key is required for OpenAI-compatible provider."
			return
		provider_options = {
			"endpoint_url": str(_tutor_config.get("endpoint_url", "")),
			"model": str(_tutor_config.get("model", "")),
			"api_key": str(_tutor_config.get("api_key", "")),
			"timeout_sec": float(_tutor_config.get("timeout_sec", DEFAULT_OPENAI_TIMEOUT_SEC)),
		}

	assistant_input.text = ""
	_append_assistant_entry("You", question)
	_tutor_pending = true
	_refresh_tutor_input_state()
	status_label.text = "Status: requesting tutor reply..."
	tutor_requested.emit(question, provider, provider_options)

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
	_apply_toolbox_hover_visual(_toolbox_button_hovered)

func _setup_action_button_feedback() -> void:
	_action_button_icons = {
		run_button: run_icon_art,
		submit_button: submit_icon_art,
		next_button: next_icon_art,
		back_button: map_icon_art,
		extra_button: extra_icon_art,
	}
	for button_variant in _action_button_icons.keys():
		var button := button_variant as Button
		if button == null:
			continue
		button.pivot_offset = button.size * 0.5
		button.mouse_entered.connect(func() -> void: _set_action_button_visual(button, "hover"))
		button.mouse_exited.connect(func() -> void: _set_action_button_visual(button, "idle"))
		button.button_down.connect(func() -> void: _set_action_button_visual(button, "pressed"))
		button.button_up.connect(func() -> void: _set_action_button_visual(button, "hover"))
	_refresh_action_button_feedback()

func _refresh_action_button_feedback() -> void:
	for button_variant in _action_button_icons.keys():
		var button := button_variant as Button
		if button == null:
			continue
		_set_action_button_visual(button, "disabled" if button.disabled else "idle")

func _set_action_button_visual(button: Button, state: String) -> void:
	if button == null:
		return
	if button.disabled:
		state = "disabled"
	button.pivot_offset = button.size * 0.5
	var icon := _action_button_icons.get(button, null) as TextureRect
	var modulate := ACTION_BUTTON_IDLE_MODULATE
	var scale := ACTION_BUTTON_IDLE_SCALE
	match state:
		"hover":
			modulate = ACTION_BUTTON_HOVER_MODULATE
			scale = ACTION_BUTTON_HOVER_SCALE
		"pressed":
			modulate = ACTION_BUTTON_PRESSED_MODULATE
			scale = ACTION_BUTTON_PRESSED_SCALE
		"disabled":
			modulate = ACTION_BUTTON_DISABLED_MODULATE
			scale = ACTION_BUTTON_IDLE_SCALE
	button.modulate = modulate
	if icon != null:
		icon.modulate = modulate
	button.scale = scale

func _refresh_tutor_input_state() -> void:
	var has_active_level: bool = str(_current_view.get("current_level_id", "")) != ""
	var provider: String = _selected_provider()
	var requires_api_key: bool = provider == "openai_compatible"
	assistant_input.visible = true
	assistant_input.editable = has_active_level and not _tutor_pending
	assistant_api_key_input.visible = requires_api_key
	ask_tutor_button.disabled = not has_active_level or _tutor_pending
	cancel_tutor_button.disabled = not _tutor_pending
	save_tutor_config_button.disabled = false

func _append_assistant_entry(speaker: String, message: String) -> void:
	var trimmed: String = message.strip_edges()
	if trimmed == "":
		return
	if assistant_log.text.strip_edges() == "":
		assistant_log.text = "%s: %s" % [speaker, trimmed]
		return
	assistant_log.text += "\n\n%s: %s" % [speaker, trimmed]

func _reply_type_label(reply_type: String) -> String:
	match reply_type.strip_edges().to_lower():
		"concept_explanation":
			return "Byte [Concept]"
		"debug_hint":
			return "Byte [Debug]"
		"scope_refusal":
			return "Byte [Scope]"
		"solution_refusal":
			return "Byte [Policy]"
		_:
			return "Byte"

func _setup_provider_options() -> void:
	provider_option.clear()
	provider_option.add_item("Template")
	provider_option.set_item_metadata(0, "template")
	provider_option.add_item("Local")
	provider_option.set_item_metadata(1, "local")
	provider_option.add_item("OpenAI")
	provider_option.set_item_metadata(2, "openai_compatible")
	provider_option.add_item("Stub")
	provider_option.set_item_metadata(3, "stub")
	provider_option.select(0)

func _select_provider(provider: String) -> void:
	var normalized: String = provider.strip_edges().to_lower()
	for index in range(provider_option.item_count):
		var metadata: Variant = provider_option.get_item_metadata(index)
		if metadata is String and String(metadata) == normalized:
			provider_option.select(index)
			return

func _selected_provider() -> String:
	var index: int = provider_option.selected
	if index < 0:
		return "template"
	var metadata: Variant = provider_option.get_item_metadata(index)
	if metadata is String:
		return String(metadata)
	return "template"

func _apply_reply_type_visual(reply_type: String) -> void:
	var normalized: String = reply_type.strip_edges().to_lower()
	var label_text: String = "-"
	var color: Color = TUTOR_REPLY_TYPE_COLOR_DEFAULT
	match normalized:
		"next_step_hint":
			label_text = "next step hint"
			color = TUTOR_REPLY_TYPE_COLOR_HINT
		"concept_explanation":
			label_text = "concept explanation"
			color = TUTOR_REPLY_TYPE_COLOR_CONCEPT
		"debug_hint":
			label_text = "debug hint"
			color = TUTOR_REPLY_TYPE_COLOR_DEBUG
		"scope_refusal", "solution_refusal":
			label_text = normalized.replace("_", " ")
			color = TUTOR_REPLY_TYPE_COLOR_REFUSAL
		"error":
			label_text = "error"
			color = TUTOR_REPLY_TYPE_COLOR_ERROR
		_:
			if normalized != "":
				label_text = normalized.replace("_", " ")
	tutor_reply_type_label.text = "Reply type: %s" % label_text
	tutor_reply_type_label.modulate = color

func _update_cost_labels(metadata: Dictionary) -> void:
	var request_cost_text: String = "Request cost: N/A"
	var usage_text: String = ""
	var cost_data: Variant = metadata.get("cost", null)
	if cost_data is Dictionary:
		var request_cost_value: float = _try_parse_float(cost_data.get("request_cost", 0.0), 0.0)
		var accumulated_cost_value: float = _try_parse_float(cost_data.get("accumulated_cost", request_cost_value), request_cost_value)
		_total_tutor_cost = accumulated_cost_value
		request_cost_text = "Request cost: $%.6f" % request_cost_value
	elif metadata.get("usage", null) is Dictionary:
		var usage: Dictionary = metadata.get("usage", {})
		usage_text = "Usage: in %s / out %s tokens" % [
			str(usage.get("prompt_tokens", 0)),
			str(usage.get("completion_tokens", 0)),
		]
	tutor_request_cost_label.text = usage_text if usage_text != "" else request_cost_text
	tutor_total_cost_label.text = "Total cost: $%.6f" % _total_tutor_cost

func _try_parse_float(value: Variant, fallback: float) -> float:
	if value is float or value is int:
		return float(value)
	if value is String:
		var text_value: String = String(value).strip_edges()
		if text_value != "" and text_value.is_valid_float():
			return float(text_value)
	return fallback

func _reset_tutor_stats() -> void:
	_apply_reply_type_visual("")
	tutor_request_cost_label.text = "Request cost: N/A"
	tutor_total_cost_label.text = "Total cost: $0.000000"

func _on_toolbox_button_mouse_entered() -> void:
	_toolbox_button_hovered = true
	_apply_toolbox_hover_visual(true)

func _on_toolbox_button_mouse_exited() -> void:
	_toolbox_button_hovered = false
	_apply_toolbox_hover_visual(false)

func _apply_toolbox_hover_visual(hovered: bool) -> void:
	if toolbox_button == null:
		return
	var modulate := TOOLBOX_DISABLED_MODULATE if toolbox_button.disabled else TOOLBOX_IDLE_PYTHON_MODULATE
	var texture: Texture2D = null
	if toolbox_button.disabled:
		texture = _toolbox_button_active_texture if _toolbox_locked else _toolbox_button_idle_texture
	else:
		if _toolbox_locked:
			texture = _toolbox_button_idle_texture if hovered else _toolbox_button_active_texture
			modulate = TOOLBOX_HOVER_TOOLBOX_MODULATE if hovered else TOOLBOX_IDLE_TOOLBOX_MODULATE
		else:
			texture = _toolbox_button_active_texture if hovered else _toolbox_button_idle_texture
			modulate = TOOLBOX_HOVER_PYTHON_MODULATE if hovered else TOOLBOX_IDLE_PYTHON_MODULATE
	toolbox_button.modulate = modulate
	if toolbox_panel_art != null:
		if texture != null:
			toolbox_panel_art.texture = texture
		toolbox_panel_art.modulate = modulate
