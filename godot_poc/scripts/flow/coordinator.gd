extends Control
class_name FlowCoordinator

class NullToolboxController extends RefCounted:
	func setup(_owner: Control, _demo_screen: Control, _practice_screen: Control) -> void:
		pass

	func prewarm_helper() -> void:
		pass

	func process_tick() -> void:
		pass

	func is_challenge_workspace_active() -> bool:
		return false

	func workspace_python_code() -> String:
		return ""

	func workspace_block_json() -> Dictionary:
		return {}

	func request_demo_convert() -> void:
		pass

	func ensure_demo_helper(_demo_view: Dictionary) -> void:
		pass

	func toggle_challenge_helper(_practice_view: Dictionary, _current_page: String) -> void:
		pass

	func apply_lock_state() -> void:
		pass

	func debug_state_lines() -> Array[String]:
		return ["toolbox=disabled"]

	func handle_page_changed(_page: String, _demo_view: Dictionary) -> void:
		pass

	func stop_helper(_force_kill: bool, _current_page: String) -> void:
		pass

const DEFAULT_PRACTICE_CODE := "print(3)\n"
const BridgeStateStoreScript = preload("res://scripts/bridge/bridge_state_store.gd")
const QuestMapMapperScript = preload("res://scripts/map/mappers/quest_map_mapper.gd")
const GameFlowFeedbackPresenterScript = preload("res://scripts/game_flow/presentation/feedback_presenter.gd")
const GameFlowMapperScript = preload("res://scripts/game_flow/mappers/mapper.gd")
const TutorUserConfigScript = preload("res://scripts/game_flow/tutor/tutor_user_config.gd")
const FlowPageRouterScript = preload("res://scripts/flow/page_router.gd")
const FlowScreenPresenterScript = preload("res://scripts/flow/screen_presenter.gd")
const FlowToolboxControllerScript = preload("res://scripts/flow/toolbox/toolbox_controller.gd")
const DEFAULT_TUTOR_REQUEST_TIMEOUT_SEC := 30.0
const TUTOR_REQUEST_TIMEOUT_GRACE_SEC := 5.0
const MAX_TUTOR_CONVERSATION_MESSAGES := 12
const MAX_RECENT_TUTOR_FEEDBACK_ITEMS := 4

@onready var python_bridge_client = $PythonBridgeClient
@onready var entry_screen = $EntryScreen
@onready var map_screen = $MapScreen
@onready var scene_screen = $SceneScreen
@onready var demo_screen = $DemoScreen
@onready var practice_screen = $PracticeScreen
@onready var debug_margin: MarginContainer = $Margin
@onready var debug_panel: PanelContainer = $Margin/DebugPanel
@onready var response_text: RichTextLabel = $Margin/DebugPanel/DebugMargin/DebugRoot/ResponseText

var _state_store: RefCounted
var _current_page: String = "entry"
var _toolbox_controller: RefCounted
var _awaiting_tutor_reply: bool = false
var _active_tutor_request_tag: String = ""
var _tutor_request_seq: int = 0
var _active_tutor_timeout_sec: float = DEFAULT_TUTOR_REQUEST_TIMEOUT_SEC
var _tutor_timeout_timer: Timer
var _tutor_conversation_id: String = ""
var _tutor_conversation_level_id: String = ""
var _tutor_conversation_history: Array[Dictionary] = []


func _ready() -> void:
	_state_store = BridgeStateStoreScript.new()
	_ensure_toolbox_controller()
	_tutor_timeout_timer = Timer.new()
	_tutor_timeout_timer.one_shot = true
	_tutor_timeout_timer.timeout.connect(_on_tutor_request_timeout)
	add_child(_tutor_timeout_timer)

	entry_screen.start_bridge_requested.connect(_on_start_bridge_requested)
	entry_screen.reset_requested.connect(_on_reset_requested)
	entry_screen.create_profile_requested.connect(_on_create_profile_requested)
	map_screen.start_bridge_requested.connect(_on_start_bridge_requested)
	map_screen.reset_requested.connect(_on_reset_requested)
	map_screen.advance_requested.connect(_on_advance_requested)
	map_screen.node_open_requested.connect(_on_open_current_node_requested)
	map_screen.debug_toggled.connect(_on_debug_toggled)
	map_screen.stage_story_requested.connect(_on_stage_story_requested)
	map_screen.stage_demo_requested.connect(_on_stage_demo_requested)
	map_screen.stage_practice_requested.connect(_on_stage_practice_requested)
	map_screen.tutor_settings_saved.connect(_on_tutor_config_saved)
	scene_screen.advance_requested.connect(_on_advance_requested)
	scene_screen.back_requested.connect(_show_map_page)
	demo_screen.advance_requested.connect(_on_demo_advance_requested)
	demo_screen.convert_requested.connect(_on_demo_convert_requested)
	demo_screen.back_requested.connect(_show_map_page)
	practice_screen.run_requested.connect(_on_run_requested)
	practice_screen.submit_requested.connect(_on_submit_requested)
	practice_screen.next_requested.connect(_on_next_requested)
	practice_screen.open_toolbox_requested.connect(_on_open_toolbox_requested)
	practice_screen.tutor_requested.connect(_on_tutor_requested)
	practice_screen.tutor_cancel_requested.connect(_on_tutor_cancel_requested)
	practice_screen.tutor_config_saved.connect(_on_tutor_config_saved)
	practice_screen.toolbox_confirmation_accepted.connect(_on_toolbox_confirmation_accepted)
	practice_screen.back_requested.connect(_show_map_page)
	python_bridge_client.bridge_started.connect(_on_bridge_started)
	python_bridge_client.bridge_failed.connect(_on_bridge_failed)
	python_bridge_client.response_received.connect(_on_response_received)
	python_bridge_client.tutor_response_received.connect(_on_tutor_response_received)
	python_bridge_client.tutor_request_failed.connect(_on_tutor_request_failed)

	entry_screen.show_profile({})
	entry_screen.set_status("Status: start bridge, then create your profile.")
	entry_screen.set_bridge_running(false)
	practice_screen.initialize(DEFAULT_PRACTICE_CODE)
	map_screen.show_map(QuestMapMapperScript.empty_map_view("Click Start Bridge, then Reset to load the current quest map."))
	map_screen.set_status("Status: idle")
	map_screen.set_note("Use Reset to load the latest quest state. Group and slot state now come directly from bridge map_route data.")
	map_screen.set_bridge_running(false)
	map_screen.set_can_advance(false)
	map_screen.set_current_node_enterable(false)
	scene_screen.show_placeholder("No scene loaded yet.")
	scene_screen.set_status("Scene flow is idle.")
	scene_screen.set_can_advance(false)
	scene_screen.set_can_go_back(false)
	demo_screen.show_placeholder("Demo placeholder will appear here.")
	demo_screen.set_status("Demo flow is idle.")
	demo_screen.set_can_convert(false)
	demo_screen.set_can_advance(false)
	demo_screen.set_can_go_back(true)
	practice_screen.show_practice({})
	practice_screen.show_feedback(GameFlowFeedbackPresenterScript.empty_feedback_view("Feedback will appear here."))
	practice_screen.set_status("Practice flow is idle.")
	practice_screen.set_can_run(false)
	practice_screen.set_can_submit(false)
	practice_screen.set_can_next(false)
	var tutor_config: Dictionary = TutorUserConfigScript.load_config()
	practice_screen.set_tutor_config(tutor_config)
	map_screen.set_tutor_config(tutor_config)
	_set_debug_visible(false)
	_show_page("entry")
	set_process(true)


func _process(_delta: float) -> void:
	if _ensure_toolbox_controller():
		_toolbox_controller.process_tick()


func _on_start_bridge_requested() -> void:
	entry_screen.set_status("Status: starting bridge...")
	map_screen.set_status("Status: starting bridge...")
	python_bridge_client.start_bridge()


func _on_reset_requested() -> void:
	_cancel_active_tutor_request()
	_clear_tutor_conversation()
	entry_screen.set_status("Status: requesting reset...")
	map_screen.set_status("Status: requesting reset...")
	python_bridge_client.send_reset()


func _on_create_profile_requested(player_name: String, gender: String) -> void:
	entry_screen.set_status("Status: creating profile...")
	python_bridge_client.send_create_player_profile(player_name, gender)


func _on_open_current_node_requested() -> void:
	if not _state_store.has_state():
		map_screen.set_note("No GameState loaded yet. Start the bridge and press Reset first.")
		return

	var state: Dictionary = _state_store.get_state()
	var target_page: String = FlowPageRouterScript.resolved_page_for_state(state)
	if target_page != "map":
		_show_page(target_page)
		return

	if _state_can_advance(state):
		map_screen.set_note("Current node has no standalone page yet. Use Advance to move to the next story node.")
		return

	map_screen.set_note("Current node cannot be opened as a separate page.")


func _on_stage_story_requested(group_id: String) -> void:
	if not _state_store.has_state():
		map_screen.set_note("No GameState loaded yet. Start the bridge and press Reset first.")
		return
	map_screen.set_status("Status: opening story...")
	python_bridge_client.send_start_group_story(group_id)


func _on_stage_demo_requested(group_id: String) -> void:
	if not _state_store.has_state():
		map_screen.set_note("No GameState loaded yet. Start the bridge and press Reset first.")
		return
	map_screen.set_status("Status: opening demo...")
	python_bridge_client.send_start_group_demo(group_id)


func _on_stage_practice_requested(group_id: String) -> void:
	if not _state_store.has_state():
		map_screen.set_note("No GameState loaded yet. Start the bridge and press Reset first.")
		return
	map_screen.set_status("Status: opening practice...")
	python_bridge_client.send_start_group_practice(group_id)


func _on_advance_requested() -> void:
	if _current_page == "scene" and _state_store.has_state() and not bool(_state_store.get_state().get("intro_completed", false)):
		scene_screen.set_status("Status: completing opening intro...")
		python_bridge_client.send_complete_intro()
		return
	if _current_page == "scene":
		scene_screen.set_status("Status: requesting advance...")
	else:
		map_screen.set_status("Status: requesting advance...")
	python_bridge_client.send_advance()


func _on_run_requested(python_code: String) -> void:
	if _ensure_toolbox_controller() and _toolbox_controller.is_challenge_workspace_active():
		practice_screen.set_status("Status: running toolkit...")
		python_bridge_client.send_verify_toolbox_level(_toolbox_controller.workspace_python_code(), _toolbox_controller.workspace_block_json())
		return
	practice_screen.set_status("Status: running code...")
	python_bridge_client.send_run_level(python_code)


func _on_submit_requested(python_code: String) -> void:
	practice_screen.set_status("Status: submitting code...")
	python_bridge_client.send_submit_level(python_code)


func _on_next_requested() -> void:
	practice_screen.set_status("Status: moving to next level...")
	python_bridge_client.send_next_level()


func _on_demo_advance_requested() -> void:
	demo_screen.set_status("Status: continuing demo flow...")
	python_bridge_client.send_advance()


func _on_demo_convert_requested() -> void:
	if not _ensure_toolbox_controller():
		demo_screen.set_status("Demo toolbox is unavailable.")
		return
	_toolbox_controller.request_demo_convert()
	var demo_view: Dictionary = _current_demo_view()
	_toolbox_controller.ensure_demo_helper(demo_view)


func _on_open_toolbox_requested() -> void:
	if not _ensure_toolbox_controller():
		practice_screen.set_status("Toolbox is unavailable.")
		return
	var practice_view: Dictionary = _current_practice_view()
	if bool(practice_view.get("toolbox_opened", false)):
		_toolbox_controller.toggle_challenge_helper(practice_view, _current_page)
		return
	var penalty_percent: Variant = practice_view.get("toolbox_penalty_percent", null)
	if penalty_percent == null:
		_toolbox_controller.toggle_challenge_helper(practice_view, _current_page)
		return
	practice_screen.prompt_toolbox_confirmation(int(penalty_percent))


func _on_tutor_requested(question: String, provider: String, provider_options: Dictionary) -> void:
	if not _state_store.has_state():
		practice_screen.show_tutor_error("No GameState loaded yet. Start the bridge and press Reset first.")
		return

	var state: Dictionary = _state_store.get_state()
	var level_id: String = _resolve_current_level_id(state)
	if level_id == "":
		practice_screen.show_tutor_error("Tutor is available only when a level is active.")
		return
	if _tutor_conversation_level_id != level_id:
		_reset_tutor_conversation(level_id)

	var payload: Dictionary = {
		"question": question,
		"provider": provider,
		"level_id": level_id,
		"python_code": practice_screen.current_python_code(),
		"block_json": null,
	}
	if _tutor_conversation_id != "":
		payload["conversation_id"] = _tutor_conversation_id
	if not _tutor_conversation_history.is_empty():
		payload["conversation_history"] = _copy_tutor_conversation_history()
	var recent_feedback: Array[String] = _build_recent_tutor_feedback(state, level_id)
	if not recent_feedback.is_empty():
		payload["recent_feedback"] = recent_feedback
	if not provider_options.is_empty():
		payload["provider_options"] = provider_options

	if _ensure_toolbox_controller() and _toolbox_controller.is_challenge_workspace_active():
		payload["block_json"] = _toolbox_controller.workspace_block_json()

	_tutor_request_seq += 1
	_active_tutor_request_tag = "tutor_%d" % _tutor_request_seq
	_awaiting_tutor_reply = true
	_active_tutor_timeout_sec = _resolve_tutor_timeout_sec(provider_options)
	_start_tutor_timeout(_active_tutor_timeout_sec + TUTOR_REQUEST_TIMEOUT_GRACE_SEC)
	_append_tutor_conversation("user", question)
	practice_screen.set_status("Status: requesting tutor reply...")
	python_bridge_client.send_tutor_reply_async(payload, _active_tutor_request_tag)


func _on_tutor_cancel_requested() -> void:
	if _active_tutor_request_tag != "":
		python_bridge_client.cancel_tutor_request(_active_tutor_request_tag)
	_stop_tutor_timeout()
	_active_tutor_request_tag = ""
	_awaiting_tutor_reply = false
	practice_screen.set_status("Status: tutor request cancelled locally.")


func _on_tutor_config_saved(config: Dictionary) -> void:
	var saved: bool = TutorUserConfigScript.save_config(config)
	if not saved:
		map_screen.set_status("Status: failed to save tutor settings.")
		practice_screen.set_status("Status: failed to save tutor settings.")
		return

	var refreshed_config: Dictionary = TutorUserConfigScript.load_config()
	map_screen.set_tutor_config(refreshed_config)
	practice_screen.set_tutor_config(refreshed_config)
	map_screen.set_status("Status: tutor settings saved locally.")
	practice_screen.set_status("Status: tutor settings saved locally.")


func _on_toolbox_confirmation_accepted() -> void:
	if not _ensure_toolbox_controller():
		return
	python_bridge_client.send_confirm_toolbox_open()
	var practice_view: Dictionary = _current_practice_view()
	if bool(practice_view.get("toolbox_opened", false)):
		_toolbox_controller.toggle_challenge_helper(practice_view, _current_page)


func _on_debug_toggled(debug_visible: bool) -> void:
	_set_debug_visible(debug_visible)


func _on_bridge_started() -> void:
	entry_screen.set_status("Status: bridge running")
	entry_screen.set_bridge_running(true)
	map_screen.set_status("Status: bridge running")
	map_screen.set_bridge_running(true)
	map_screen.set_note("Bridge started. Press Reset to fetch current state.")
	response_text.text = "Bridge started. Click Reset to fetch current state."
	if _ensure_toolbox_controller():
		_toolbox_controller.prewarm_helper()


func _on_bridge_failed(message: String) -> void:
	if _awaiting_tutor_reply:
		_stop_tutor_timeout()
		_awaiting_tutor_reply = false
		_active_tutor_request_tag = ""
		practice_screen.show_tutor_error(message)
		return

	response_text.text = message
	_apply_error_ui(
		"Status: bridge error",
		"Bridge error:\n%s" % message,
		"Bridge Error",
		message
	)


func _on_response_received(response: Dictionary) -> void:
	response_text.text = JSON.stringify(response, "  ")
	_state_store.apply_response(response)

	var state: Variant = response.get("state", null)
	if state is Dictionary:
		_apply_success_state(state, response)
		return

	_apply_error_response(response)


func _apply_success_state(state: Dictionary, response: Dictionary) -> void:
	var map_view: Dictionary = QuestMapMapperScript.map_game_state(state)
	var view_model: Dictionary = GameFlowMapperScript.map_game_state(state)
	var feedback_view: Dictionary = GameFlowFeedbackPresenterScript.build_feedback_view(view_model, response)
	var can_open: bool = FlowPageRouterScript.current_state_has_openable_page(state)
	entry_screen.show_profile(view_model.get("player_profile_view", {}))
	entry_screen.set_status(_entry_status_text(view_model.get("player_profile_view", {})))
	entry_screen.set_bridge_running(python_bridge_client.is_running())
	FlowScreenPresenterScript.render_map_view(map_screen, map_view, state, view_model, can_open)
	FlowScreenPresenterScript.render_flow_views(scene_screen, demo_screen, practice_screen, view_model, feedback_view)
	scene_screen.set_can_go_back(bool(state.get("intro_completed", false)))
	if _ensure_toolbox_controller():
		_toolbox_controller.apply_lock_state()
	_append_debug_state(view_model)
	_route_after_response(state)


func _append_debug_state(view_model: Dictionary) -> void:
	var practice_view: Dictionary = view_model.get("practice_view", {})
	var action_view: Dictionary = view_model.get("action_view", {})
	var focus_owner: Control = get_viewport().gui_get_focus_owner()
	var focus_name: String = "<none>"
	if focus_owner != null:
		focus_name = "%s (%s)" % [focus_owner.name, focus_owner.get_class()]

	var debug_lines: Array[String] = [
		"",
		"--- UI Debug ---",
		"current_page=%s" % _current_page,
		"practice_view.code_editable=%s" % str(practice_view.get("code_editable", false)),
		"action_view.can_submit=%s" % str(action_view.get("can_submit", false)),
		"action_view.can_next=%s" % str(action_view.get("can_next", false)),
		"focus_owner=%s" % focus_name,
	]
	if _ensure_toolbox_controller():
		debug_lines.append_array(_toolbox_controller.debug_state_lines())
	else:
		debug_lines.append("toolbox_controller=unavailable")
	response_text.text += "\n" + "\n".join(debug_lines)


func _state_can_advance(state: Dictionary) -> bool:
	return FlowScreenPresenterScript.can_advance_from_view_model(GameFlowMapperScript.map_game_state(state))


func _route_after_response(state: Dictionary) -> void:
	_show_page(FlowPageRouterScript.resolved_page_for_state(state))


func _apply_error_response(response: Dictionary) -> void:
	var error_text: String = str(response.get("error", "Unknown error"))
	_apply_error_ui(
		"Status: request failed",
		"Request failed:\n%s" % error_text,
		"Request Failed",
		error_text
	)


func _apply_error_ui(map_status: String, map_note: String, feedback_title: String, feedback_body: String) -> void:
	entry_screen.set_status(map_status)
	FlowScreenPresenterScript.apply_error_ui(map_screen, scene_screen, demo_screen, practice_screen, map_status, map_note, feedback_title, feedback_body)
	if _ensure_toolbox_controller():
		_toolbox_controller.apply_lock_state()
	_show_page("entry")


func _show_map_page() -> void:
	_show_page("map")


func _show_page(page: String) -> void:
	_current_page = page
	FlowPageRouterScript.show_page(page, entry_screen, map_screen, scene_screen, demo_screen, practice_screen)
	var demo_view: Dictionary = _current_demo_view()
	if _ensure_toolbox_controller():
		_toolbox_controller.handle_page_changed(page, demo_view)
	if page != "challenge":
		_cancel_active_tutor_request()
		_clear_tutor_conversation()


func _current_view_model() -> Dictionary:
	if not _state_store.has_state():
		return {}
	return GameFlowMapperScript.map_game_state(_state_store.get_state())


func _current_demo_view() -> Dictionary:
	return _current_view_model().get("demo_view", {})


func _current_practice_view() -> Dictionary:
	return _current_view_model().get("practice_view", {})

func _set_debug_visible(debug_visible: bool) -> void:
	debug_margin.visible = debug_visible
	debug_panel.visible = debug_visible
	map_screen.set_debug_visible(debug_visible)


func _entry_status_text(profile_view: Dictionary) -> String:
	if bool(profile_view.get("profile_created", false)):
		return "Status: profile ready, opening briefing unlocked"
	return "Status: create your profile to enter the opening briefing"


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and _toolbox_controller != null:
		_toolbox_controller.stop_helper(true, _current_page)


func _ensure_toolbox_controller() -> bool:
	if _toolbox_controller != null:
		return true
	if FlowToolboxControllerScript != null:
		_toolbox_controller = FlowToolboxControllerScript.new()
	else:
		_toolbox_controller = NullToolboxController.new()
	_toolbox_controller.setup(self, demo_screen, practice_screen)
	return true


func _on_tutor_response_received(response: Dictionary, request_tag: String) -> void:
	if request_tag != _active_tutor_request_tag:
		return

	_stop_tutor_timeout()
	response_text.text = JSON.stringify(response, "  ")
	_active_tutor_request_tag = ""
	_awaiting_tutor_reply = false

	if not bool(response.get("ok", false)):
		practice_screen.show_tutor_error(str(response.get("error", "Unknown tutor error")))
		return

	var tutor_variant: Variant = response.get("tutor", null)
	if not (tutor_variant is Dictionary):
		practice_screen.show_tutor_error("Tutor response payload is missing.")
		return

	var tutor_payload: Dictionary = tutor_variant
	var reply_type: String = str(tutor_payload.get("reply_type", "next_step_hint"))
	var content: String = str(tutor_payload.get("content", ""))
	var metadata_variant: Variant = tutor_payload.get("metadata", {})
	var metadata: Dictionary = {}
	if metadata_variant is Dictionary:
		metadata = metadata_variant
	_append_tutor_conversation("assistant", content)
	practice_screen.show_tutor_reply(reply_type, content, metadata)


func _on_tutor_request_failed(message: String, request_tag: String) -> void:
	if request_tag != _active_tutor_request_tag:
		return

	_stop_tutor_timeout()
	response_text.text = "Tutor async request failed: %s" % message
	_active_tutor_request_tag = ""
	_awaiting_tutor_reply = false
	practice_screen.show_tutor_error(message)


func _on_tutor_request_timeout() -> void:
	if not _awaiting_tutor_reply:
		return

	var timed_out_tag: String = _active_tutor_request_tag
	if timed_out_tag != "":
		python_bridge_client.cancel_tutor_request(timed_out_tag)

	response_text.text = "Tutor request timed out after %.1fs (%s)." % [_active_tutor_timeout_sec, timed_out_tag]
	_active_tutor_request_tag = ""
	_awaiting_tutor_reply = false
	practice_screen.show_tutor_error("Tutor request timed out. Please try again.")


func _resolve_tutor_timeout_sec(provider_options: Dictionary) -> float:
	var timeout_raw: Variant = provider_options.get("timeout_sec", DEFAULT_TUTOR_REQUEST_TIMEOUT_SEC)
	if timeout_raw is float or timeout_raw is int:
		var timeout_value: float = float(timeout_raw)
		if timeout_value > 0:
			return timeout_value
	return DEFAULT_TUTOR_REQUEST_TIMEOUT_SEC


func _start_tutor_timeout(timeout_sec: float) -> void:
	if _tutor_timeout_timer == null:
		return
	_tutor_timeout_timer.wait_time = max(1.0, timeout_sec)
	_tutor_timeout_timer.start()


func _stop_tutor_timeout() -> void:
	if _tutor_timeout_timer == null:
		return
	_tutor_timeout_timer.stop()


func _cancel_active_tutor_request() -> void:
	if _active_tutor_request_tag != "":
		python_bridge_client.cancel_tutor_request(_active_tutor_request_tag)
	_stop_tutor_timeout()
	_active_tutor_request_tag = ""
	_awaiting_tutor_reply = false


func _clear_tutor_conversation() -> void:
	_tutor_conversation_id = ""
	_tutor_conversation_level_id = ""
	_tutor_conversation_history.clear()


func _reset_tutor_conversation(level_id: String) -> void:
	_tutor_conversation_level_id = level_id
	_tutor_conversation_id = "tutor_%s_%d" % [level_id, Time.get_ticks_msec()]
	_tutor_conversation_history.clear()


func _append_tutor_conversation(role: String, content: String) -> void:
	var trimmed: String = content.strip_edges()
	if trimmed == "":
		return
	_tutor_conversation_history.append({
		"role": role,
		"content": trimmed,
	})
	while _tutor_conversation_history.size() > MAX_TUTOR_CONVERSATION_MESSAGES:
		_tutor_conversation_history.remove_at(0)


func _copy_tutor_conversation_history() -> Array[Dictionary]:
	var copied: Array[Dictionary] = []
	for item in _tutor_conversation_history:
		copied.append(item.duplicate(true))
	return copied


func _build_recent_tutor_feedback(state: Dictionary, level_id: String) -> Array[String]:
	var last_submission_variant: Variant = state.get("last_submission", null)
	if not (last_submission_variant is Dictionary):
		return []

	var last_submission: Dictionary = last_submission_variant
	if str(last_submission.get("level_id", "")) != level_id:
		return []

	var summary_lines: Array[String] = []
	var status_label: String = str(last_submission.get("status_label", "")).strip_edges()
	if status_label != "":
		summary_lines.append("status: %s" % status_label)

	var analysis_summary: String = str(last_submission.get("analysis_summary", "")).strip_edges()
	if analysis_summary != "":
		summary_lines.append("analysis: %s" % _truncate_tutor_feedback_line(analysis_summary, 180))

	var judge_summary: String = str(last_submission.get("judge_summary", "")).strip_edges()
	if judge_summary != "":
		summary_lines.append("judge: %s" % _truncate_tutor_feedback_line(judge_summary, 180))

	var output_text: String = str(last_submission.get("output_text", "")).strip_edges()
	if output_text != "":
		var single_line_output: String = output_text.replace("\n", " | ")
		summary_lines.append("output: %s" % _truncate_tutor_feedback_line(single_line_output, 140))

	if summary_lines.size() > MAX_RECENT_TUTOR_FEEDBACK_ITEMS:
		summary_lines.resize(MAX_RECENT_TUTOR_FEEDBACK_ITEMS)
	return summary_lines


func _truncate_tutor_feedback_line(text: String, max_length: int) -> String:
	var trimmed: String = text.strip_edges()
	if trimmed.length() <= max_length:
		return trimmed
	if max_length <= 3:
		return trimmed.substr(0, max_length)
	return "%s..." % trimmed.substr(0, max_length - 3)


func _resolve_current_level_id(state: Dictionary) -> String:
	var practice_variant: Variant = state.get("practice", null)
	if practice_variant is Dictionary:
		var practice: Dictionary = practice_variant
		var from_practice: String = str(practice.get("current_level_id", practice.get("level_id", "")))
		if from_practice != "":
			return from_practice

	var demo_variant: Variant = state.get("demo", null)
	if demo_variant is Dictionary:
		var demo: Dictionary = demo_variant
		var from_demo: String = str(demo.get("current_level_id", demo.get("level_id", "")))
		if from_demo != "":
			return from_demo

	return ""

