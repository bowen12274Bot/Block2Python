extends Control
class_name GameFlowCoordinator

const DEFAULT_PRACTICE_CODE := "print(3)\n"
const DEFAULT_TOOLBOX_PYTHON_REL_PATH := "../.venv/Scripts/python.exe"
const TOOLBOX_HTML_REL_PATH := "../assets/blockly/index.html"
const TOOLBOX_MODULE := "block2python.clients.toolbox_window"
const TOOLBOX_LOCK_MESSAGE := "Toolbox is active. Close toolbox to resume Python editing."
const TOOLBOX_RESULT_DIR := "user://toolbox_runtime"
const BridgeStateStoreScript = preload("res://scripts/bridge/bridge_state_store.gd")
const WindowAlignmentHelperScript = preload("res://scripts/bridge/window_alignment.gd")
const WindowLayoutSyncScript = preload("res://scripts/bridge/window_layout_sync.gd")
const QuestMapMapperScript = preload("res://scripts/map/quest_map_mapper.gd")
const GameFlowFeedbackPresenterScript = preload("res://scripts/game_flow/game_flow_feedback_presenter.gd")
const GameFlowMapperScript = preload("res://scripts/game_flow/game_flow_mapper.gd")
const GameFlowPageRouterScript = preload("res://scripts/flow/game_flow_page_router.gd")
const GameFlowScreenPresenterScript = preload("res://scripts/flow/game_flow_screen_presenter.gd")

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
var _toolbox_helper_pid: int = -1
var _toolbox_result_file: String = ""
var _toolbox_layout_file: String = ""
var _toolbox_last_result_token: String = ""
var _toolbox_last_layout_payload: String = ""
var _toolbox_active_level_id: String = ""
var _toolbox_workspace_python_code: String = ""
var _toolbox_workspace_block_json: Dictionary = {}

func _ready() -> void:
	_state_store = BridgeStateStoreScript.new()
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
	scene_screen.advance_requested.connect(_on_advance_requested)
	scene_screen.back_requested.connect(_show_map_page)
	demo_screen.advance_requested.connect(_on_demo_advance_requested)
	demo_screen.back_requested.connect(_show_map_page)
	practice_screen.run_requested.connect(_on_run_requested)
	practice_screen.submit_requested.connect(_on_submit_requested)
	practice_screen.next_requested.connect(_on_next_requested)
	practice_screen.open_toolbox_requested.connect(_on_open_toolbox_requested)
	practice_screen.back_requested.connect(_show_map_page)
	python_bridge_client.bridge_started.connect(_on_bridge_started)
	python_bridge_client.bridge_failed.connect(_on_bridge_failed)
	python_bridge_client.response_received.connect(_on_response_received)

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
	demo_screen.set_can_advance(false)
	demo_screen.set_can_go_back(true)
	practice_screen.show_practice({})
	practice_screen.show_feedback(GameFlowFeedbackPresenterScript.empty_feedback_view("Feedback will appear here."))
	practice_screen.set_status("Practice flow is idle.")
	practice_screen.set_can_run(false)
	practice_screen.set_can_submit(false)
	practice_screen.set_can_next(false)
	_set_debug_visible(false)
	_show_page("entry")
	set_process(true)

func _process(_delta: float) -> void:
	_poll_toolbox_helper()

func _on_start_bridge_requested() -> void:
	entry_screen.set_status("Status: starting bridge...")
	map_screen.set_status("Status: starting bridge...")
	python_bridge_client.start_bridge()

func _on_reset_requested() -> void:
	entry_screen.set_status("Status: requesting reset...")
	map_screen.set_status("Status: requesting reset...")
	python_bridge_client.send_reset()

func _on_create_profile_requested(name: String, gender: String) -> void:
	entry_screen.set_status("Status: creating profile...")
	python_bridge_client.send_create_player_profile(name, gender)

func _on_open_current_node_requested() -> void:
	if not _state_store.has_state():
		map_screen.set_note("No GameState loaded yet. Start the bridge and press Reset first.")
		return

	var state: Dictionary = _state_store.get_state()
	var target_page: String = GameFlowPageRouterScript.resolved_page_for_state(state)
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
	if _toolbox_helper_pid > 0 and not _toolbox_workspace_block_json.is_empty():
		practice_screen.set_status("Status: running toolkit...")
		python_bridge_client.send_verify_toolbox_level(_toolbox_workspace_python_code, _toolbox_workspace_block_json)
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
	demo_screen.set_status("Status: continuing demo placeholder...")
	python_bridge_client.send_advance()

func _on_open_toolbox_requested() -> void:
	if _toolbox_helper_pid > 0:
		_stop_toolbox_helper(true)
		practice_screen.set_status("Toolbox closed.")
		return
	var practice_view: Dictionary = GameFlowMapperScript.map_game_state(_state_store.get_state()).get("practice_view", {}) if _state_store.has_state() else {}
	if str(practice_view.get("current_level_id", "")) == "":
		practice_screen.set_status("Toolbox is only available when a practice level is active.")
		return
	if not bool(practice_view.get("toolbox_allowed", false)):
		practice_screen.set_status("Toolbox is only available in practice challenges.")
		return
	var launch_request: Dictionary = _build_toolbox_launch_request(practice_view)
	if launch_request.is_empty():
		return
	var pid: int = OS.create_process(str(launch_request.get("python_path", "")), launch_request.get("args", PackedStringArray()), false)
	if pid <= 0:
		practice_screen.set_status("Failed to launch toolbox window.")
		return
	_toolbox_helper_pid = pid
	_toolbox_result_file = str(launch_request.get("result_file", ""))
	_toolbox_layout_file = str(launch_request.get("layout_file", ""))
	_toolbox_last_result_token = ""
	_toolbox_last_layout_payload = ""
	_toolbox_active_level_id = str(practice_view.get("current_level_id", ""))
	_sync_toolbox_layout_file()
	practice_screen.set_toolbox_lock(true, TOOLBOX_LOCK_MESSAGE)

func _on_debug_toggled(debug_visible: bool) -> void:
	_set_debug_visible(debug_visible)

func _on_bridge_started() -> void:
	entry_screen.set_status("Status: bridge running")
	entry_screen.set_bridge_running(true)
	map_screen.set_status("Status: bridge running")
	map_screen.set_bridge_running(true)
	map_screen.set_note("Bridge started. Press Reset to fetch current state.")
	response_text.text = "Bridge started. Click Reset to fetch current state."

func _on_bridge_failed(message: String) -> void:
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
	var can_open: bool = GameFlowPageRouterScript.current_state_has_openable_page(state)
	entry_screen.show_profile(view_model.get("player_profile_view", {}))
	entry_screen.set_status(_entry_status_text(view_model.get("player_profile_view", {})))
	entry_screen.set_bridge_running(python_bridge_client.is_running())
	GameFlowScreenPresenterScript.render_map_view(map_screen, map_view, state, view_model, can_open)
	GameFlowScreenPresenterScript.render_flow_views(scene_screen, demo_screen, practice_screen, view_model, feedback_view)
	scene_screen.set_can_go_back(bool(state.get("intro_completed", false)))
	_apply_toolbox_lock_state()
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
		"toolbox_helper_pid=%s" % str(_toolbox_helper_pid),
	]
	response_text.text += "\n" + "\n".join(debug_lines)

func _state_can_advance(state: Dictionary) -> bool:
	return GameFlowScreenPresenterScript.can_advance_from_view_model(GameFlowMapperScript.map_game_state(state))

func _route_after_response(state: Dictionary) -> void:
	_show_page(GameFlowPageRouterScript.resolved_page_for_state(state))

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
	GameFlowScreenPresenterScript.apply_error_ui(map_screen, scene_screen, demo_screen, practice_screen, map_status, map_note, feedback_title, feedback_body)
	_apply_toolbox_lock_state()
	_show_page("entry")

func _show_map_page() -> void:
	_show_page("map")

func _show_page(page: String) -> void:
	_current_page = page
	if page != "challenge" and _toolbox_helper_pid > 0:
		_stop_toolbox_helper(true)
	GameFlowPageRouterScript.show_page(page, entry_screen, map_screen, scene_screen, demo_screen, practice_screen)
	_apply_toolbox_lock_state()

func _apply_toolbox_lock_state() -> void:
	practice_screen.set_toolbox_lock(_toolbox_helper_pid > 0, TOOLBOX_LOCK_MESSAGE if _toolbox_helper_pid > 0 else "")

func _build_toolbox_launch_request(practice_view: Dictionary) -> Dictionary:
	var python_path: String = _resolve_project_path(DEFAULT_TOOLBOX_PYTHON_REL_PATH)
	if not FileAccess.file_exists(python_path):
		practice_screen.set_status("Python launcher not found: %s" % python_path)
		return {}
	var html_path: String = _resolve_project_path(TOOLBOX_HTML_REL_PATH)
	if not FileAccess.file_exists(html_path):
		practice_screen.set_status("Blockly HTML not found: %s" % html_path)
		return {}

	var runtime_dir: String = ProjectSettings.globalize_path(TOOLBOX_RESULT_DIR)
	DirAccess.make_dir_recursive_absolute(runtime_dir)
	var result_file: String = runtime_dir.path_join("toolbox_%s_%s.json" % [str(practice_view.get("current_level_id", "level")).replace("/", "_"), str(Time.get_ticks_msec())])
	if FileAccess.file_exists(result_file):
		DirAccess.remove_absolute(result_file)
	var layout_file: String = runtime_dir.path_join("toolbox_layout_%s_%s.json" % [str(practice_view.get("current_level_id", "level")).replace("/", "_"), str(Time.get_ticks_msec())])

	var args := PackedStringArray([
		"-m",
		TOOLBOX_MODULE,
		"--level-id",
		str(practice_view.get("current_level_id", "")),
		"--result-file",
		result_file,
		"--html-path",
		html_path,
		"--layout-file",
		layout_file,
	])
	return {
		"python_path": python_path,
		"args": args,
		"result_file": result_file,
		"layout_file": layout_file,
	}

func _poll_toolbox_helper() -> void:
	if _toolbox_helper_pid <= 0:
		return
	_sync_toolbox_layout_file()
	_poll_toolbox_result_file()

func _poll_toolbox_result_file() -> void:
	if _toolbox_result_file == "" or not FileAccess.file_exists(_toolbox_result_file):
		return
	var file := FileAccess.open(_toolbox_result_file, FileAccess.READ)
	if file == null:
		return
	var raw: String = file.get_as_text()
	if raw.strip_edges() == "":
		return
	var parsed: Variant = JSON.parse_string(raw)
	if not (parsed is Dictionary):
		return
	var payload: Dictionary = parsed
	var status: String = str(payload.get("status", ""))
	var request_id: String = str(payload.get("request_id", ""))
	var token: String = "%s:%s" % [status, request_id]
	if token == _toolbox_last_result_token:
		return
	_toolbox_last_result_token = token
	_handle_toolbox_result(payload)

func _sync_toolbox_layout_file() -> void:
	if _toolbox_layout_file == "" or _toolbox_active_level_id == "":
		return
	var payload: Dictionary = _build_toolbox_layout_payload()
	_toolbox_last_layout_payload = WindowLayoutSyncScript.sync_layout_file(_toolbox_layout_file, payload, _toolbox_last_layout_payload)

func _build_toolbox_layout_payload() -> Dictionary:
	var owner_title: String = get_window().title if get_window() != null else str(ProjectSettings.get_setting("application/config/name", "Block2Python Godot POC"))
	var target_control: Control = practice_screen.practice_panel.get_toolbox_target_control()
	return WindowAlignmentHelperScript.build_layout_payload(
		_toolbox_active_level_id,
		owner_title,
		int(DisplayServer.window_get_native_handle(DisplayServer.WINDOW_HANDLE)),
		target_control,
		practice_screen.visible and practice_screen.is_visible_in_tree()
	)

func _handle_toolbox_result(payload: Dictionary) -> void:
	var status: String = str(payload.get("status", ""))
	if status == "toolbox_sync":
		var level_id: String = str(payload.get("level_id", ""))
		if level_id != _toolbox_active_level_id:
			return
		var python_code: String = str(payload.get("python_code", ""))
		var block_json: Variant = payload.get("block_json", {})
		if block_json is Dictionary:
			_toolbox_workspace_python_code = python_code
			_toolbox_workspace_block_json = block_json
		return
	if status == "toolbox_closed":
		_stop_toolbox_helper(false)

func _stop_toolbox_helper(force_kill: bool) -> void:
	if _toolbox_helper_pid > 0 and force_kill:
		OS.kill(_toolbox_helper_pid)
	_toolbox_helper_pid = -1
	_toolbox_result_file = ""
	_toolbox_layout_file = ""
	_toolbox_last_result_token = ""
	_toolbox_last_layout_payload = ""
	_toolbox_active_level_id = ""
	_toolbox_workspace_python_code = ""
	_toolbox_workspace_block_json = {}
	practice_screen.set_toolbox_lock(false)
	if _current_page == "challenge":
		practice_screen.set_status("Practice flow ready")
		practice_screen.focus_code_editor()

func _resolve_project_path(relative_path: String) -> String:
	return ProjectSettings.globalize_path("res://%s" % relative_path)

func _set_debug_visible(debug_visible: bool) -> void:
	debug_margin.visible = debug_visible
	debug_panel.visible = debug_visible
	map_screen.set_debug_visible(debug_visible)

func _entry_status_text(profile_view: Dictionary) -> String:
	if bool(profile_view.get("profile_created", false)):
		return "Status: profile ready, opening briefing unlocked"
	return "Status: create your profile to enter the opening briefing"

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_stop_toolbox_helper(true)
