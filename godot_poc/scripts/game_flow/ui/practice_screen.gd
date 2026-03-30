extends Control
class_name PracticeScreen

signal run_requested(python_code: String)
signal submit_requested(python_code: String)
signal next_requested()
signal open_toolbox_requested()
signal tutor_requested(question: String, provider: String, provider_options: Dictionary)
signal tutor_cancel_requested()
signal tutor_config_saved(config: Dictionary)
signal toolbox_confirmation_accepted()
signal back_requested()

const DEFAULT_OPENAI_ENDPOINT := "https://api.openai.com/v1/chat/completions"
const DEFAULT_OPENAI_MODEL := "gpt-4o-mini"
const DEFAULT_OPENAI_TIMEOUT_SEC := 30.0
const DEFAULT_LOCAL_OLLAMA_ENDPOINT := "http://127.0.0.1:11434/v1/chat/completions"
const DEFAULT_LOCAL_OLLAMA_MODEL := "qwen3.5:0.8b"
const DEFAULT_LOCAL_OLLAMA_TIMEOUT_SEC := 20.0
const TUTOR_STREAM_INTERVAL_SEC := 0.03
const TUTOR_REPLY_TYPE_COLOR_DEFAULT := Color(0.72549, 0.756863, 0.854902, 0.84)
const TUTOR_REPLY_TYPE_COLOR_HINT := Color(0.572549, 0.862745, 0.705882, 0.96)
const TUTOR_REPLY_TYPE_COLOR_CONCEPT := Color(0.564706, 0.760784, 0.94902, 0.96)
const TUTOR_REPLY_TYPE_COLOR_DEBUG := Color(0.968627, 0.788235, 0.462745, 0.96)
const TUTOR_REPLY_TYPE_COLOR_REFUSAL := Color(0.952941, 0.572549, 0.572549, 0.96)
const TUTOR_REPLY_TYPE_COLOR_ERROR := Color(0.972549, 0.501961, 0.501961, 0.96)

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
@onready var practice_panel = $Margin/Root/Body/CenterColumn/PracticePanel
@onready var feedback_panel = $Margin/Root/Body/CenterColumn/OutputPanel
@onready var assistant_log: RichTextLabel = $Margin/Root/Body/RightColumn/AssistantPanel/AssistantMargin/AssistantRoot/AssistantLog
@onready var assistant_input: LineEdit = $Margin/Root/Body/RightColumn/AssistantPanel/AssistantMargin/AssistantRoot/AssistantInput
@onready var provider_option: OptionButton = $Margin/Root/Body/RightColumn/AssistantPanel/AssistantMargin/AssistantRoot/ConfigRow/ProviderOption
@onready var assistant_api_key_input: LineEdit = $Margin/Root/Body/RightColumn/AssistantPanel/AssistantMargin/AssistantRoot/ConfigRow/ApiKeyInput
@onready var api_key_visibility_button: Button = $Margin/Root/Body/RightColumn/AssistantPanel/AssistantMargin/AssistantRoot/ConfigRow/ApiKeyVisibilityButton
@onready var save_tutor_config_button: Button = $Margin/Root/Body/RightColumn/AssistantPanel/AssistantMargin/AssistantRoot/ConfigRow/SaveTutorConfigButton
@onready var provider_form: VBoxContainer = $Margin/Root/Body/RightColumn/AssistantPanel/AssistantMargin/AssistantRoot/ConfigForm
@onready var endpoint_input: LineEdit = $Margin/Root/Body/RightColumn/AssistantPanel/AssistantMargin/AssistantRoot/ConfigForm/EndpointInput
@onready var model_input: LineEdit = $Margin/Root/Body/RightColumn/AssistantPanel/AssistantMargin/AssistantRoot/ConfigForm/ModelInput
@onready var timeout_input: LineEdit = $Margin/Root/Body/RightColumn/AssistantPanel/AssistantMargin/AssistantRoot/ConfigForm/TimeoutInput
@onready var system_prompt_input: TextEdit = $Margin/Root/Body/RightColumn/AssistantPanel/AssistantMargin/AssistantRoot/ConfigForm/SystemPromptInput
@onready var provider_form_hint_label: Label = $Margin/Root/Body/RightColumn/AssistantPanel/AssistantMargin/AssistantRoot/ConfigForm/ProviderFormHint
@onready var ask_tutor_button: Button = $Margin/Root/Body/RightColumn/AssistantPanel/AssistantMargin/AssistantRoot/ActionRow/AskTutorButton
@onready var cancel_tutor_button: Button = $Margin/Root/Body/RightColumn/AssistantPanel/AssistantMargin/AssistantRoot/ActionRow/CancelTutorButton
@onready var tutor_reply_type_label: Label = $Margin/Root/Body/RightColumn/AssistantPanel/AssistantMargin/AssistantRoot/TutorStats/ReplyTypeLabel
@onready var tutor_request_cost_label: Label = $Margin/Root/Body/RightColumn/AssistantPanel/AssistantMargin/AssistantRoot/TutorStats/RequestCostLabel
@onready var tutor_total_cost_label: Label = $Margin/Root/Body/RightColumn/AssistantPanel/AssistantMargin/AssistantRoot/TutorStats/TotalCostLabel
@onready var toolkit_hint: RichTextLabel = $Margin/Root/Body/RightColumn/ToolkitPanel/ToolkitMargin/ToolkitRoot/ToolkitHint
@onready var toolbox_button: Button = $Margin/Root/Body/RightColumn/ToolkitPanel/ToolkitMargin/ToolkitRoot/ToolboxButton

var _toolbox_confirmation_dialog: ConfirmationDialog
var _base_can_run: bool = false
var _base_can_submit: bool = false
var _base_can_next: bool = false
var _base_can_open_toolbox: bool = false
var _base_code_editable: bool = false
var _toolbox_locked: bool = false
var _current_view: Dictionary = {}
var _toolbox_status_message: String = ""
var _assistant_enabled: bool = false
var _tutor_request_pending: bool = false
var _total_tutor_cost: float = 0.0
var _provider_endpoint_url: String = DEFAULT_OPENAI_ENDPOINT
var _provider_model: String = DEFAULT_OPENAI_MODEL
var _provider_timeout_sec: float = DEFAULT_OPENAI_TIMEOUT_SEC
var _provider_system_prompt: String = ""
var _api_key_visible: bool = false
var _tutor_reply_stream_timer: Timer
var _tutor_reply_streaming: bool = false
var _tutor_reply_stream_source_log: String = ""
var _tutor_reply_stream_content: String = ""
var _tutor_reply_stream_visible_chars: int = 0
var _tutor_reply_stream_reply_type: String = ""
var _tutor_reply_stream_metadata: Dictionary = {}

func _ready() -> void:
	run_button.pressed.connect(_on_run_button_pressed)
	submit_button.pressed.connect(_on_submit_button_pressed)
	next_button.pressed.connect(_on_next_button_pressed)
	toolbox_button.pressed.connect(_on_toolbox_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)
	assistant_input.text_submitted.connect(_on_assistant_input_submitted)
	assistant_input.text_changed.connect(_on_assistant_input_changed)
	assistant_api_key_input.text_changed.connect(_on_provider_line_input_changed)
	endpoint_input.text_changed.connect(_on_provider_line_input_changed)
	model_input.text_changed.connect(_on_provider_line_input_changed)
	timeout_input.text_changed.connect(_on_provider_line_input_changed)
	system_prompt_input.text_changed.connect(_on_provider_text_input_changed)
	ask_tutor_button.pressed.connect(_on_ask_tutor_button_pressed)
	cancel_tutor_button.pressed.connect(_on_cancel_tutor_button_pressed)
	save_tutor_config_button.pressed.connect(_on_save_tutor_config_button_pressed)
	api_key_visibility_button.pressed.connect(_on_api_key_visibility_button_pressed)
	provider_option.item_selected.connect(_on_provider_option_selected)
	_setup_provider_options()
	_apply_api_key_visibility()
	_sync_provider_form_inputs()
	_refresh_provider_form()
	_reset_tutor_stats()
	assistant_input.editable = false
	_tutor_reply_stream_timer = Timer.new()
	_tutor_reply_stream_timer.wait_time = TUTOR_STREAM_INTERVAL_SEC
	_tutor_reply_stream_timer.one_shot = false
	_tutor_reply_stream_timer.timeout.connect(_on_tutor_reply_stream_tick)
	add_child(_tutor_reply_stream_timer)
	_toolbox_confirmation_dialog = ConfirmationDialog.new()
	_toolbox_confirmation_dialog.title = "Tool Kit Warning"
	_toolbox_confirmation_dialog.confirmed.connect(_on_toolbox_confirmation_confirmed)
	add_child(_toolbox_confirmation_dialog)
	_refresh_tutor_controls()

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
	battery_bar.value = float(practice_view.get("battery_percent", 0))
	battery_percent_label.text = "Battery: %s%%" % str(practice_view.get("battery_percent", 0))
	battery_threshold_label.text = "Threshold: %s%%" % str(practice_view.get("battery_threshold_percent", 80))
	assistant_log.text = str(practice_view.get("assistant_chat_text", "Byte: Practice assistant is standing by."))
	_assistant_enabled = str(practice_view.get("current_level_id", "")) != ""
	assistant_input.placeholder_text = "Ask Byte about this level..." if _assistant_enabled else "Tutor is available after entering a level."
	toolkit_hint.text = str(practice_view.get("toolkit_hint", "Open the toolkit when you need help exploring a block-based solution."))
	practice_panel.show_practice(practice_view)
	_apply_toolbox_lock_state()
	_refresh_tutor_controls()

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
	toolbox_button.text = "Close Tool Kit" if _toolbox_locked else "Open Tool Kit"
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
	_select_provider(str(config.get("provider", "template")))
	assistant_api_key_input.text = str(config.get("api_key", ""))
	_provider_endpoint_url = str(config.get("endpoint_url", DEFAULT_OPENAI_ENDPOINT))
	_provider_model = str(config.get("model", DEFAULT_OPENAI_MODEL))
	_provider_system_prompt = str(config.get("system_prompt", ""))
	var timeout_raw: Variant = config.get("timeout_sec", DEFAULT_OPENAI_TIMEOUT_SEC)
	if timeout_raw is float or timeout_raw is int:
		var timeout_value: float = float(timeout_raw)
		if timeout_value > 0:
			_provider_timeout_sec = timeout_value
	_sync_provider_form_inputs()
	_refresh_provider_form()
	_refresh_tutor_controls()

func tutor_config() -> Dictionary:
	_read_provider_form_values()
	return {
		"provider": _selected_provider(),
		"api_key": assistant_api_key_input.text.strip_edges(),
		"endpoint_url": _provider_endpoint_url,
		"model": _provider_model,
		"timeout_sec": _provider_timeout_sec,
		"system_prompt": _provider_system_prompt,
	}

func show_tutor_reply(reply_type: String, content: String, metadata: Dictionary = {}) -> void:
	_start_tutor_reply_stream(reply_type, content, metadata)

func show_tutor_error(message: String) -> void:
	_stop_tutor_reply_stream(false)
	_append_assistant_entry("System", message)
	status_label.text = "Status: tutor request failed"
	_apply_reply_type_visual("error")
	set_tutor_pending(false)

func set_tutor_pending(pending: bool) -> void:
	_tutor_request_pending = pending
	_refresh_tutor_controls()

func _apply_toolbox_lock_state() -> void:
	practice_panel.set_code_editable(_base_code_editable and not _toolbox_locked)
	run_button.disabled = not _base_can_run
	submit_button.disabled = (not _base_can_submit) or _toolbox_locked
	next_button.disabled = (not _base_can_next) or _toolbox_locked
	toolbox_button.disabled = not _base_can_open_toolbox
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

func _on_assistant_input_submitted(_text: String) -> void:
	_on_ask_tutor_button_pressed()

func _on_assistant_input_changed(_text: String) -> void:
	_refresh_tutor_controls()

func _on_ask_tutor_button_pressed() -> void:
	if _tutor_request_pending:
		return

	var question: String = assistant_input.text.strip_edges()
	if question == "":
		status_label.text = "Status: enter a tutor question first."
		_refresh_tutor_controls()
		return

	var provider: String = _selected_provider()
	_read_provider_form_values()
	if provider == "openai_compatible" or provider == "local":
		if _provider_endpoint_url == "" or _provider_model == "":
			status_label.text = "Status: endpoint and model are required for this provider."
			_refresh_tutor_controls()
			return
	if provider == "openai_compatible" and assistant_api_key_input.text.strip_edges() == "":
		status_label.text = "Status: API key is required for OpenAI-compatible provider."
		_refresh_tutor_controls()
		return

	_append_assistant_entry("You", question)
	assistant_input.text = ""
	status_label.text = "Status: requesting tutor reply..."
	set_tutor_pending(true)
	tutor_requested.emit(question, provider, _build_provider_options(provider))

func _on_cancel_tutor_button_pressed() -> void:
	if not _tutor_request_pending:
		return
	_stop_tutor_reply_stream(true)
	status_label.text = "Status: cancelling tutor request..."
	set_tutor_pending(false)
	tutor_cancel_requested.emit()

func _on_save_tutor_config_button_pressed() -> void:
	_read_provider_form_values()
	tutor_config_saved.emit(tutor_config())
	status_label.text = "Status: tutor settings saved (%s)." % _selected_provider()

func _on_provider_option_selected(_index: int) -> void:
	_refresh_provider_form()
	_refresh_tutor_controls()

func _on_provider_line_input_changed(_value: String) -> void:
	_refresh_tutor_controls()

func _on_provider_text_input_changed() -> void:
	_refresh_tutor_controls()

func _on_api_key_visibility_button_pressed() -> void:
	_api_key_visible = not _api_key_visible
	_apply_api_key_visibility()

func _on_toolbox_confirmation_confirmed() -> void:
	status_label.text = "Status: confirming toolbox penalty..."
	toolbox_confirmation_accepted.emit()

func _on_back_button_pressed() -> void:
	status_label.text = "Status: returning to map..."
	back_requested.emit()

func _setup_provider_options() -> void:
	provider_option.clear()
	provider_option.add_item("Template")
	provider_option.set_item_metadata(0, "template")
	provider_option.add_item("Local Ollama Selector")
	provider_option.set_item_metadata(1, "local")
	provider_option.add_item("OpenAI Compatible")
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

func _build_provider_options(provider: String) -> Dictionary:
	_read_provider_form_values()
	if provider != "openai_compatible" and provider != "local":
		return {}

	var options: Dictionary = {
		"endpoint_url": _provider_endpoint_url,
		"model": _provider_model,
		"timeout_sec": _provider_timeout_sec,
	}
	var api_key: String = assistant_api_key_input.text.strip_edges()
	if api_key != "":
		options["api_key"] = api_key
	if _provider_system_prompt != "":
		options["system_prompt"] = _provider_system_prompt
	return options

func _refresh_tutor_controls() -> void:
	var provider: String = _selected_provider()
	var has_question: bool = assistant_input.text.strip_edges() != ""
	var requires_api_key: bool = provider == "openai_compatible"
	var requires_provider_form: bool = provider == "openai_compatible" or provider == "local"
	var has_api_key: bool = assistant_api_key_input.text.strip_edges() != ""
	var has_endpoint_model: bool = true
	if requires_provider_form:
		has_endpoint_model = endpoint_input.text.strip_edges() != "" and model_input.text.strip_edges() != ""

	assistant_input.editable = _assistant_enabled and not _tutor_request_pending
	ask_tutor_button.disabled = (
		not _assistant_enabled
		or _tutor_request_pending
		or _tutor_reply_streaming
		or not has_question
		or not has_endpoint_model
		or (requires_api_key and not has_api_key)
	)
	cancel_tutor_button.disabled = not _tutor_request_pending


func _refresh_provider_form() -> void:
	var provider: String = _selected_provider()
	var needs_provider_form: bool = provider == "openai_compatible" or provider == "local"
	provider_form.visible = needs_provider_form

	if provider == "local":
		if _provider_endpoint_url.strip_edges() == "" or _provider_endpoint_url == DEFAULT_OPENAI_ENDPOINT:
			_provider_endpoint_url = DEFAULT_LOCAL_OLLAMA_ENDPOINT
		if _provider_model.strip_edges() == "" or _provider_model == DEFAULT_OPENAI_MODEL:
			_provider_model = DEFAULT_LOCAL_OLLAMA_MODEL
		if _provider_timeout_sec <= 0:
			_provider_timeout_sec = DEFAULT_LOCAL_OLLAMA_TIMEOUT_SEC
		assistant_api_key_input.placeholder_text = "Ollama API key (optional)"
		provider_form_hint_label.text = "Local selector uses Ollama (OpenAI-compatible endpoint)."
	elif provider == "openai_compatible":
		if _provider_endpoint_url.strip_edges() == "":
			_provider_endpoint_url = DEFAULT_OPENAI_ENDPOINT
		if _provider_model.strip_edges() == "":
			_provider_model = DEFAULT_OPENAI_MODEL
		if _provider_timeout_sec <= 0:
			_provider_timeout_sec = DEFAULT_OPENAI_TIMEOUT_SEC
		assistant_api_key_input.placeholder_text = "API key (required)"
		provider_form_hint_label.text = "Remote provider requires API key and endpoint credentials."
	else:
		assistant_api_key_input.placeholder_text = "API key"
		provider_form_hint_label.text = ""

	_sync_provider_form_inputs()


func _sync_provider_form_inputs() -> void:
	endpoint_input.text = _provider_endpoint_url
	model_input.text = _provider_model
	timeout_input.text = "%.1f" % _provider_timeout_sec
	system_prompt_input.text = _provider_system_prompt


func _read_provider_form_values() -> void:
	_provider_endpoint_url = endpoint_input.text.strip_edges()
	_provider_model = model_input.text.strip_edges()
	_provider_system_prompt = system_prompt_input.text.strip_edges()

	var timeout_text: String = timeout_input.text.strip_edges()
	if timeout_text == "":
		return
	if timeout_text.is_valid_float():
		var parsed_timeout: float = float(timeout_text)
		if parsed_timeout > 0:
			_provider_timeout_sec = parsed_timeout


func _apply_api_key_visibility() -> void:
	assistant_api_key_input.secret = not _api_key_visible
	api_key_visibility_button.text = "Hide" if _api_key_visible else "Show"

func _start_tutor_reply_stream(reply_type: String, content: String, metadata: Dictionary) -> void:
	_stop_tutor_reply_stream(false)
	_tutor_reply_streaming = true
	_tutor_reply_stream_source_log = assistant_log.text
	_tutor_reply_stream_content = content
	_tutor_reply_stream_visible_chars = 0
	_tutor_reply_stream_reply_type = reply_type
	_tutor_reply_stream_metadata = metadata.duplicate(true)

	if _tutor_reply_stream_content == "":
		_append_assistant_entry("Byte", "")
		_finish_tutor_reply_stream()
		return

	status_label.text = "Status: streaming tutor reply..."
	_refresh_tutor_controls()
	_update_tutor_reply_stream_preview()
	_tutor_reply_stream_timer.start()


func _on_tutor_reply_stream_tick() -> void:
	if not _tutor_reply_streaming:
		return

	var total_length: int = _tutor_reply_stream_content.length()
	if total_length <= 0:
		_finish_tutor_reply_stream()
		return

	var step: int = 12
	if total_length >= 240:
		step = 20
	if total_length >= 480:
		step = 32

	_tutor_reply_stream_visible_chars = min(total_length, _tutor_reply_stream_visible_chars + step)
	_update_tutor_reply_stream_preview()
	if _tutor_reply_stream_visible_chars >= total_length:
		_finish_tutor_reply_stream()


func _update_tutor_reply_stream_preview() -> void:
	var visible_text: String = _tutor_reply_stream_content.substr(0, _tutor_reply_stream_visible_chars)
	_set_tutor_stream_log(visible_text)


func _set_tutor_stream_log(message: String) -> void:
	var speaker: String = _reply_type_speaker_label(_tutor_reply_stream_reply_type)
	if _tutor_reply_stream_source_log.strip_edges() == "":
		assistant_log.text = "%s: %s" % [speaker, message]
		return
	assistant_log.text = "%s\n\n%s: %s" % [_tutor_reply_stream_source_log, speaker, message]


func _finish_tutor_reply_stream() -> void:
	if _tutor_reply_stream_timer != null:
		_tutor_reply_stream_timer.stop()
	if _tutor_reply_streaming:
		_set_tutor_stream_log(_tutor_reply_stream_content)
	_tutor_reply_streaming = false
	_apply_reply_type_visual(_tutor_reply_stream_reply_type)
	_update_cost_labels(_tutor_reply_stream_metadata)
	status_label.text = "Status: tutor reply received"
	_refresh_tutor_controls()
	set_tutor_pending(false)


func _stop_tutor_reply_stream(restore_source_log: bool) -> void:
	if _tutor_reply_stream_timer != null:
		_tutor_reply_stream_timer.stop()
	if restore_source_log and _tutor_reply_streaming:
		assistant_log.text = _tutor_reply_stream_source_log
	_tutor_reply_streaming = false

func _append_assistant_entry(speaker: String, message: String) -> void:
	var trimmed: String = message.strip_edges()
	if trimmed == "":
		return
	if assistant_log.text.strip_edges() == "":
		assistant_log.text = "%s: %s" % [speaker, trimmed]
		return
	assistant_log.text += "\n\n%s: %s" % [speaker, trimmed]

func _update_cost_labels(metadata: Dictionary) -> void:
	var request_cost_text: String = "Request cost: N/A"
	var cost_data: Variant = metadata.get("cost", null)
	if cost_data is Dictionary:
		var request_cost_value: float = _try_parse_float(cost_data.get("request_cost", 0.0), 0.0)
		var accumulated_cost_value: float = _try_parse_float(cost_data.get("accumulated_cost", request_cost_value), request_cost_value)
		_total_tutor_cost = accumulated_cost_value
		request_cost_text = "Request cost: $%.6f" % request_cost_value
	elif metadata.get("usage", null) is Dictionary:
		var usage: Dictionary = metadata.get("usage", {})
		request_cost_text = "Usage: in %s / out %s tokens" % [
			str(usage.get("prompt_tokens", 0)),
			str(usage.get("completion_tokens", 0)),
		]

	tutor_request_cost_label.text = request_cost_text
	tutor_total_cost_label.text = "Total cost: $%.6f" % _total_tutor_cost

func _try_parse_float(value: Variant, fallback: float) -> float:
	if value is float or value is int:
		return float(value)
	if value is String:
		var text_value: String = String(value).strip_edges()
		if text_value == "":
			return fallback
		if text_value.is_valid_float():
			return float(text_value)
	return fallback

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
		"scope_refusal":
			label_text = "scope refusal"
			color = TUTOR_REPLY_TYPE_COLOR_REFUSAL
		"solution_refusal":
			label_text = "solution refusal"
			color = TUTOR_REPLY_TYPE_COLOR_REFUSAL
		"error":
			label_text = "error"
			color = TUTOR_REPLY_TYPE_COLOR_ERROR
		_:
			if normalized != "":
				label_text = normalized

	tutor_reply_type_label.text = "Reply type: %s" % label_text
	tutor_reply_type_label.modulate = color

func _reply_type_speaker_label(reply_type: String) -> String:
	var normalized: String = reply_type.strip_edges().to_lower()
	match normalized:
		"concept_explanation":
			return "Byte [Concept]"
		"next_step_hint":
			return "Byte [Hint]"
		"debug_hint":
			return "Byte [Debug]"
		"scope_refusal":
			return "Byte [Scope]"
		"solution_refusal":
			return "Byte [Policy]"
		_:
			return "Byte"

func _reset_tutor_stats() -> void:
	_apply_reply_type_visual("")
	tutor_request_cost_label.text = "Request cost: N/A"
	tutor_total_cost_label.text = "Total cost: $0.000000"
