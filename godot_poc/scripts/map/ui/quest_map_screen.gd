extends Control

const QuestMapGroupCardBindingScript = preload("res://scripts/map/ui/quest_map_group_card_binding.gd")
const QuestMapGroupCardRendererScript = preload("res://scripts/map/ui/quest_map_group_card_renderer.gd")
const QuestMapOverlayPresenterScript = preload("res://scripts/map/presentation/quest_map_overlay_presenter.gd")
const QuestMapGroupNotePresenterScript = preload("res://scripts/map/presentation/quest_map_group_note_presenter.gd")
const QuestMapGroupFlowRulesScript = preload("res://scripts/map/presentation/quest_map_group_flow_rules.gd")
const TutorUserConfigScript = preload("res://scripts/game_flow/tutor/tutor_user_config.gd")

signal start_bridge_requested()
signal reset_requested()
signal advance_requested()
signal node_open_requested()
signal debug_toggled(visible: bool)
signal stage_story_requested(group_id: String)
signal stage_demo_requested(group_id: String)
signal stage_practice_requested(group_id: String)
signal tutor_settings_saved(config: Dictionary)

@onready var start_bridge_button: Button = get_node_or_null("HudMargin/HudRoot/TopBar/ActionRow/StartBridgeButton")
@onready var reset_button: Button = get_node_or_null("HudMargin/HudRoot/TopBar/ActionRow/ResetButton")
@onready var advance_button: Button = get_node_or_null("HudMargin/HudRoot/TopBar/ActionRow/AdvanceButton")
@onready var open_node_button: Button = get_node_or_null("HudMargin/HudRoot/TopBar/ActionRow/OpenNodeButton")
@onready var debug_toggle_button: Button = get_node_or_null("HudMargin/HudRoot/TopBar/ActionRow/DebugToggleButton")
@onready var settings_button: Button = get_node_or_null("HudMargin/HudRoot/TopBar/ActionRow/SettingsButton")
@onready var status_label: Label = get_node_or_null("HudMargin/HudRoot/StatusLabel")
@onready var quest_map_stage = get_node_or_null("StageFrame")
@onready var stage_overlay = get_node_or_null("StageOverlay")
@onready var settings_overlay: Control = get_node_or_null("SettingsOverlay")
@onready var settings_provider_option: OptionButton = get_node_or_null("SettingsOverlay/Center/SettingsPanel/SettingsMargin/SettingsRoot/ConfigRow/ProviderOption")
@onready var settings_api_key_input: LineEdit = get_node_or_null("SettingsOverlay/Center/SettingsPanel/SettingsMargin/SettingsRoot/ConfigRow/ApiKeyInput")
@onready var settings_api_key_visibility_button: Button = get_node_or_null("SettingsOverlay/Center/SettingsPanel/SettingsMargin/SettingsRoot/ConfigRow/ApiKeyVisibilityButton")
@onready var settings_endpoint_input: LineEdit = get_node_or_null("SettingsOverlay/Center/SettingsPanel/SettingsMargin/SettingsRoot/ConfigForm/EndpointInput")
@onready var settings_model_input: LineEdit = get_node_or_null("SettingsOverlay/Center/SettingsPanel/SettingsMargin/SettingsRoot/ConfigForm/ModelInput")
@onready var settings_timeout_input: LineEdit = get_node_or_null("SettingsOverlay/Center/SettingsPanel/SettingsMargin/SettingsRoot/ConfigForm/TimeoutInput")
@onready var settings_system_prompt_input: TextEdit = get_node_or_null("SettingsOverlay/Center/SettingsPanel/SettingsMargin/SettingsRoot/ConfigForm/SystemPromptInput")
@onready var settings_provider_form: VBoxContainer = get_node_or_null("SettingsOverlay/Center/SettingsPanel/SettingsMargin/SettingsRoot/ConfigForm")
@onready var settings_provider_form_hint_label: Label = get_node_or_null("SettingsOverlay/Center/SettingsPanel/SettingsMargin/SettingsRoot/ConfigForm/ProviderFormHint")
@onready var settings_save_button: Button = get_node_or_null("SettingsOverlay/Center/SettingsPanel/SettingsMargin/SettingsRoot/ActionRow/SaveButton")
@onready var settings_close_button: Button = get_node_or_null("SettingsOverlay/Center/SettingsPanel/SettingsMargin/SettingsRoot/HeaderRow/CloseSettingsButton")
@onready var settings_cancel_button: Button = get_node_or_null("SettingsOverlay/Center/SettingsPanel/SettingsMargin/SettingsRoot/ActionRow/CancelButton")
@onready var settings_status_label: Label = get_node_or_null("SettingsOverlay/Center/SettingsPanel/SettingsMargin/SettingsRoot/SettingsStatus")

var _last_map_view: Dictionary = {}
var _group_lookup: Dictionary = {}
var _selected_group_id: String = ""
var _group_cards: Dictionary = {}
var _provider_endpoint_url: String = TutorUserConfigScript.DEFAULT_LOCAL_OLLAMA_ENDPOINT
var _provider_model: String = TutorUserConfigScript.DEFAULT_LOCAL_OLLAMA_MODEL
var _provider_timeout_sec: float = TutorUserConfigScript.DEFAULT_LOCAL_OLLAMA_TIMEOUT_SEC
var _provider_system_prompt: String = ""
var _api_key_visible: bool = false


func _ready() -> void:
	_group_cards = QuestMapGroupCardBindingScript.collect(self, Callable(self, "_on_group_pressed"))

	if start_bridge_button != null:
		start_bridge_button.pressed.connect(func() -> void:
			start_bridge_requested.emit()
		)
	if reset_button != null:
		reset_button.pressed.connect(func() -> void:
			reset_requested.emit()
		)
	if advance_button != null:
		advance_button.pressed.connect(func() -> void:
			advance_requested.emit()
		)
		advance_button.disabled = true
	if open_node_button != null:
		open_node_button.pressed.connect(func() -> void:
			node_open_requested.emit()
		)
		open_node_button.disabled = true
	if debug_toggle_button != null:
		debug_toggle_button.toggled.connect(func(button_pressed: bool) -> void:
			debug_toggled.emit(button_pressed)
		)
	if settings_button != null:
		settings_button.pressed.connect(_on_settings_button_pressed)
	if stage_overlay != null:
		stage_overlay.close_requested.connect(hide_stage_overlay)
		stage_overlay.story_requested.connect(_on_stage_story_pressed)
		stage_overlay.demo_requested.connect(_on_stage_demo_pressed)
		stage_overlay.practice_requested.connect(_on_stage_practice_pressed)

	if settings_close_button != null:
		settings_close_button.pressed.connect(_hide_settings_overlay)
	if settings_cancel_button != null:
		settings_cancel_button.pressed.connect(_hide_settings_overlay)
	if settings_save_button != null:
		settings_save_button.pressed.connect(_on_settings_save_button_pressed)
	if settings_provider_option != null:
		settings_provider_option.item_selected.connect(_on_settings_provider_selected)
	if settings_endpoint_input != null:
		settings_endpoint_input.text_changed.connect(_on_settings_line_input_changed)
	if settings_model_input != null:
		settings_model_input.text_changed.connect(_on_settings_line_input_changed)
	if settings_timeout_input != null:
		settings_timeout_input.text_changed.connect(_on_settings_line_input_changed)
	if settings_system_prompt_input != null:
		settings_system_prompt_input.text_changed.connect(_on_settings_text_input_changed)
	if settings_api_key_input != null:
		settings_api_key_input.text_changed.connect(_on_settings_line_input_changed)
	if settings_api_key_visibility_button != null:
		settings_api_key_visibility_button.pressed.connect(_on_settings_api_key_visibility_pressed)

	_setup_settings_provider_options()
	_apply_settings_api_key_visibility()
	_sync_settings_form_inputs()
	_refresh_settings_provider_form()
	_hide_settings_overlay()


func show_map(map_view: Dictionary) -> void:
	_last_map_view = map_view.duplicate(true)
	_group_lookup = _index_groups(_last_map_view)
	if quest_map_stage != null:
		quest_map_stage.show_map(map_view)
	_render_group_cards(map_view)
	if stage_overlay != null and stage_overlay.visible and _selected_group_id != "":
		var refreshed_group: Dictionary = _find_group_view(_selected_group_id)
		if refreshed_group.is_empty():
			hide_stage_overlay()
		else:
			_apply_stage_overlay(refreshed_group)


func set_status(text: String) -> void:
	if status_label != null:
		status_label.text = text


func set_tutor_config(config: Dictionary) -> void:
	_select_settings_provider(_normalize_provider_name(str(config.get("provider", "temple"))))
	if settings_api_key_input != null:
		settings_api_key_input.text = str(config.get("api_key", ""))

	_provider_endpoint_url = str(config.get("endpoint_url", TutorUserConfigScript.DEFAULT_LOCAL_OLLAMA_ENDPOINT))
	_provider_model = str(config.get("model", TutorUserConfigScript.DEFAULT_LOCAL_OLLAMA_MODEL))
	_provider_system_prompt = str(config.get("system_prompt", ""))

	var timeout_raw: Variant = config.get("timeout_sec", TutorUserConfigScript.DEFAULT_LOCAL_OLLAMA_TIMEOUT_SEC)
	if timeout_raw is float or timeout_raw is int:
		var timeout_value: float = float(timeout_raw)
		if timeout_value > 0:
			_provider_timeout_sec = timeout_value

	_sync_settings_form_inputs()
	_refresh_settings_provider_form()


func tutor_config() -> Dictionary:
	_read_settings_form_values()
	var api_key: String = ""
	if settings_api_key_input != null:
		api_key = settings_api_key_input.text.strip_edges()
	return {
		"provider": _selected_settings_provider(),
		"api_key": api_key,
		"endpoint_url": _provider_endpoint_url,
		"model": _provider_model,
		"timeout_sec": _provider_timeout_sec,
		"system_prompt": _provider_system_prompt,
	}


func set_note(text: String) -> void:
	if quest_map_stage != null:
		quest_map_stage.set_helper_text(text)


func set_bridge_running(is_running: bool) -> void:
	if start_bridge_button != null:
		start_bridge_button.disabled = is_running
	if reset_button != null:
		reset_button.disabled = not is_running
	if advance_button != null:
		advance_button.disabled = true
	if open_node_button != null:
		open_node_button.disabled = true


func set_current_node_enterable(is_enterable: bool) -> void:
	if open_node_button != null:
		open_node_button.disabled = not is_enterable


func set_can_advance(can_advance: bool) -> void:
	if advance_button != null:
		advance_button.disabled = not can_advance


func set_debug_visible(debug_visible: bool) -> void:
	if debug_toggle_button != null:
		debug_toggle_button.button_pressed = debug_visible
		debug_toggle_button.text = "Hide Debug" if debug_visible else "Show Debug"


func show_stage_overlay(group_view: Dictionary) -> void:
	_selected_group_id = str(group_view.get("group_id", ""))
	if quest_map_stage != null and quest_map_stage.has_method("set_overlay_active"):
		quest_map_stage.call("set_overlay_active", true)
	_apply_stage_overlay(group_view)


func hide_stage_overlay() -> void:
	if stage_overlay != null:
		stage_overlay.hide_overlay()
	if quest_map_stage != null and quest_map_stage.has_method("set_overlay_active"):
		quest_map_stage.call("set_overlay_active", false)
	_selected_group_id = ""


func _on_settings_button_pressed() -> void:
	_show_settings_overlay()


func _on_settings_save_button_pressed() -> void:
	if settings_status_label != null:
		settings_status_label.text = "Saving tutor settings..."
	tutor_settings_saved.emit(tutor_config())
	_hide_settings_overlay()


func _on_settings_provider_selected(_index: int) -> void:
	_refresh_settings_provider_form()


func _on_settings_line_input_changed(_text: String) -> void:
	if settings_status_label != null:
		settings_status_label.text = ""


func _on_settings_text_input_changed() -> void:
	if settings_status_label != null:
		settings_status_label.text = ""


func _on_settings_api_key_visibility_pressed() -> void:
	_api_key_visible = not _api_key_visible
	_apply_settings_api_key_visibility()


func _show_settings_overlay() -> void:
	if settings_overlay != null:
		settings_overlay.visible = true
	if settings_status_label != null:
		settings_status_label.text = ""
	set_status("Status: editing tutor settings...")


func _hide_settings_overlay() -> void:
	if settings_overlay != null:
		settings_overlay.visible = false


func _setup_settings_provider_options() -> void:
	if settings_provider_option == null:
		return
	settings_provider_option.clear()
	settings_provider_option.add_item("Temple (Local Template Selector)")
	settings_provider_option.set_item_metadata(0, "temple")
	settings_provider_option.add_item("API+Skill (Remote LLM)")
	settings_provider_option.set_item_metadata(1, "api_skill")
	settings_provider_option.add_item("Stub")
	settings_provider_option.set_item_metadata(2, "stub")
	settings_provider_option.select(0)


func _select_settings_provider(provider: String) -> void:
	if settings_provider_option == null:
		return
	var normalized: String = _normalize_provider_name(provider)
	for index in range(settings_provider_option.item_count):
		var metadata: Variant = settings_provider_option.get_item_metadata(index)
		if metadata is String and String(metadata) == normalized:
			settings_provider_option.select(index)
			return


func _selected_settings_provider() -> String:
	if settings_provider_option == null:
		return "temple"
	var index: int = settings_provider_option.selected
	if index < 0:
		return "temple"
	var metadata: Variant = settings_provider_option.get_item_metadata(index)
	if metadata is String:
		return String(metadata)
	return "temple"


func _refresh_settings_provider_form() -> void:
	if settings_provider_form == null:
		return
	var provider: String = _selected_settings_provider()
	var needs_provider_form: bool = provider == "api_skill" or provider == "temple"
	settings_provider_form.visible = needs_provider_form

	if settings_api_key_input != null:
		settings_api_key_input.visible = needs_provider_form
	if settings_api_key_visibility_button != null:
		settings_api_key_visibility_button.visible = needs_provider_form

	if provider == "temple":
		if _provider_endpoint_url.strip_edges() == "" or _provider_endpoint_url == TutorUserConfigScript.DEFAULT_OPENAI_ENDPOINT_URL:
			_provider_endpoint_url = TutorUserConfigScript.DEFAULT_LOCAL_OLLAMA_ENDPOINT
		if _provider_model.strip_edges() == "" or _provider_model == TutorUserConfigScript.DEFAULT_OPENAI_MODEL:
			_provider_model = TutorUserConfigScript.DEFAULT_LOCAL_OLLAMA_MODEL
		if _provider_timeout_sec <= 0:
			_provider_timeout_sec = TutorUserConfigScript.DEFAULT_LOCAL_OLLAMA_TIMEOUT_SEC
		if settings_api_key_input != null:
			settings_api_key_input.placeholder_text = "Ollama API key (optional)"
		if settings_provider_form_hint_label != null:
			settings_provider_form_hint_label.text = "Temple uses local lightweight model + templates for predictable tutoring output."
	elif provider == "api_skill":
		if _provider_endpoint_url.strip_edges() == "" or _provider_endpoint_url == TutorUserConfigScript.DEFAULT_OPENAI_ENDPOINT_URL:
			_provider_endpoint_url = TutorUserConfigScript.DEFAULT_LOCAL_OLLAMA_ENDPOINT
		if _provider_model.strip_edges() == "" or _provider_model == TutorUserConfigScript.DEFAULT_OPENAI_MODEL or _provider_model == TutorUserConfigScript.DEFAULT_LOCAL_OLLAMA_MODEL:
			_provider_model = TutorUserConfigScript.DEFAULT_LOCAL_OLLAMA_API_SKILL_MODEL
		if _provider_timeout_sec <= 0:
			_provider_timeout_sec = TutorUserConfigScript.DEFAULT_LOCAL_OLLAMA_API_SKILL_TIMEOUT_SEC
		if settings_api_key_input != null:
			settings_api_key_input.placeholder_text = "API key (optional for local Ollama)"
		if settings_provider_form_hint_label != null:
			settings_provider_form_hint_label.text = "API+Skill runs a full LLM with real teaching skills context."
	else:
		if settings_api_key_input != null:
			settings_api_key_input.placeholder_text = "API key"
		if settings_provider_form_hint_label != null:
			settings_provider_form_hint_label.text = "Stub is test-only and not suitable for real gameplay tutoring."

	_sync_settings_form_inputs()


func _sync_settings_form_inputs() -> void:
	if settings_endpoint_input != null:
		settings_endpoint_input.text = _provider_endpoint_url
	if settings_model_input != null:
		settings_model_input.text = _provider_model
	if settings_timeout_input != null:
		settings_timeout_input.text = "%.1f" % _provider_timeout_sec
	if settings_system_prompt_input != null:
		settings_system_prompt_input.text = _provider_system_prompt


func _read_settings_form_values() -> void:
	if settings_endpoint_input != null:
		_provider_endpoint_url = settings_endpoint_input.text.strip_edges()
	if settings_model_input != null:
		_provider_model = settings_model_input.text.strip_edges()
	if settings_system_prompt_input != null:
		_provider_system_prompt = settings_system_prompt_input.text.strip_edges()

	if settings_timeout_input == null:
		return

	var timeout_text: String = settings_timeout_input.text.strip_edges()
	if timeout_text == "":
		return
	if timeout_text.is_valid_float():
		var parsed_timeout: float = float(timeout_text)
		if parsed_timeout > 0:
			_provider_timeout_sec = parsed_timeout


func _apply_settings_api_key_visibility() -> void:
	if settings_api_key_input != null:
		settings_api_key_input.secret = not _api_key_visible
	if settings_api_key_visibility_button != null:
		settings_api_key_visibility_button.text = "Hide" if _api_key_visible else "Show"


func _normalize_provider_name(provider: String) -> String:
	var normalized: String = provider.strip_edges().to_lower()
	if normalized == "stub":
		return "stub"
	if normalized == "temple" or normalized == "template" or normalized == "local":
		return "temple"
	if normalized == "api_skill" or normalized == "api+skill" or normalized == "api-skill" or normalized == "openai_compatible":
		return "api_skill"
	return "temple"


func _render_group_cards(map_view: Dictionary) -> void:
	for card_view in _group_cards.values():
		QuestMapGroupCardRendererScript.apply_group_card(card_view, {})

	var groups_variant: Variant = map_view.get("groups", [])
	if not (groups_variant is Array):
		return

	for group_variant in groups_variant:
		if not (group_variant is Dictionary):
			continue
		var group_view: Dictionary = group_variant
		var group_id: String = str(group_view.get("group_id", ""))
		if _group_cards.has(group_id):
			QuestMapGroupCardRendererScript.apply_group_card(_group_cards[group_id], group_view)


func _on_group_pressed(group_id: String) -> void:
	var group_view: Dictionary = _find_group_view(group_id)
	if group_view.is_empty():
		set_note("Selected level group: %s" % group_id)
		return

	if not bool(group_view.get("is_enterable", false)):
		set_note("This group is still locked.")
		return

	set_note(QuestMapGroupNotePresenterScript.build_group_selection_note(group_view))
	show_stage_overlay(group_view)


func _on_stage_story_pressed() -> void:
	if _selected_group_id == "":
		return
	var group_id: String = _selected_group_id
	hide_stage_overlay()
	stage_story_requested.emit(group_id)


func _on_stage_demo_pressed() -> void:
	if _selected_group_id == "":
		return
	var group_id: String = _selected_group_id
	hide_stage_overlay()
	stage_demo_requested.emit(group_id)


func _on_stage_practice_pressed() -> void:
	if _selected_group_id == "":
		return
	var refreshed_group: Dictionary = _find_group_view(_selected_group_id)
	if refreshed_group.is_empty() or not QuestMapGroupFlowRulesScript.is_practice_unlocked(refreshed_group):
		return
	var group_id: String = _selected_group_id
	hide_stage_overlay()
	stage_practice_requested.emit(group_id)


func _apply_stage_overlay(group_view: Dictionary) -> void:
	var overlay_view: Dictionary = QuestMapOverlayPresenterScript.build_overlay_view(group_view)
	if stage_overlay != null:
		stage_overlay.show_overlay(overlay_view)


func _find_group_view(group_id: String) -> Dictionary:
	var group_view_variant: Variant = _group_lookup.get(group_id, {})
	if group_view_variant is Dictionary:
		return group_view_variant
	return {}


func _index_groups(map_view: Dictionary) -> Dictionary:
	var lookup: Dictionary = {}
	var groups_variant: Variant = map_view.get("groups", [])
	if groups_variant is Array:
		for group_view_variant in groups_variant:
			if group_view_variant is Dictionary:
				var group_view: Dictionary = group_view_variant
				lookup[str(group_view.get("group_id", ""))] = group_view
	return lookup


