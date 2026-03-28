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
var _toolbox_context: String = ""
var _demo_conversion_pending: bool = false
var _demo_conversion_requested_at_msec: int = 0
var _pending_profile_name: String = ""
var _pending_profile_gender: String = ""

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
	demo_screen.convert_requested.connect(_on_demo_convert_requested)
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
	demo_screen.set_can_convert(false)
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
	_poll_demo_conversion_timeout()

func _on_start_bridge_requested() -> void:
	entry_screen.set_status("Status: starting bridge...")
	map_screen.set_status("Status: starting bridge...")
	python_bridge_client.start_bridge()

func _on_reset_requested() -> void:
	entry_screen.set_status("Status: requesting reset...")
	map_screen.set_status("Status: requesting reset...")
	python_bridge_client.send_reset()

func _on_create_profile_requested(name: String, gender: String) -> void:
	if not python_bridge_client.is_running():
		_pending_profile_name = name
		_pending_profile_gender = gender
		entry_screen.set_status("Status: starting bridge...")
		map_screen.set_status("Status: starting bridge...")
		if not python_bridge_client.start_bridge():
			_pending_profile_name = ""
			_pending_profile_gender = ""
			entry_screen.set_status("Status: bridge error")
			return
		return
	_send_create_profile(name, gender)

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
	if _toolbox_helper_pid > 0 and _toolbox_context == "challenge" and not _toolbox_workspace_block_json.is_empty():
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
	demo_screen.set_status("Status: continuing demo flow...")
	python_bridge_client.send_advance()

func _on_demo_convert_requested() -> void:
	_demo_conversion_pending = true
	_demo_conversion_requested_at_msec = Time.get_ticks_msec()
	if _toolbox_helper_pid <= 0 or _toolbox_context != "demo":
		demo_screen.set_status("Status: connecting Blockly workspace...")
		demo_screen.set_workspace_ready(false)
		_ensure_demo_toolbox_helper()
		return
	demo_screen.set_workspace_ready(true)
	demo_screen.set_status("Status: requesting latest block conversion...")
	if _toolbox_workspace_python_code.strip_edges() != "":
		demo_screen.set_python_preview(_toolbox_workspace_python_code)

func _on_open_toolbox_requested() -> void:
	if _toolbox_helper_pid > 0 and _toolbox_context == "challenge":
		_stop_toolbox_helper(true)
		practice_screen.set_status("Toolbox closed.")
		return
	var practice_view: Dictionary = GameFlowMapperScript.map_game_state(_state_store.get_state()).get("practice_view", {}) if _state_store.has_state() else {}
	var current_level_id: String = str(practice_view.get("current_level_id", ""))
	if current_level_id == "":
		practice_screen.set_status("Toolbox is only available when a practice level is active.")
		return
	if not bool(practice_view.get("toolbox_allowed", false)):
		practice_screen.set_status("Toolbox is only available in practice challenges.")
		return
	if _toolbox_helper_pid > 0:
		_stop_toolbox_helper(true)
	var launch_request: Dictionary = _build_toolbox_launch_request(current_level_id, "challenge")
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
	_toolbox_active_level_id = current_level_id
	_toolbox_context = "challenge"
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
	if _pending_profile_name != "" or _pending_profile_gender != "":
		var pending_name: String = _pending_profile_name
		var pending_gender: String = _pending_profile_gender
		_pending_profile_name = ""
		_pending_profile_gender = ""
		_send_create_profile(pending_name, pending_gender)

func _on_bridge_failed(message: String) -> void:
	_pending_profile_name = ""
	_pending_profile_gender = ""
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
		"toolbox_context=%s" % _toolbox_context,
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
	if _toolbox_helper_pid > 0:
		var keep_demo_helper: bool = page == "demo" and _toolbox_context == "demo"
		var keep_practice_helper: bool = page == "challenge" and _toolbox_context == "challenge"
		if not keep_demo_helper and not keep_practice_helper:
			_stop_toolbox_helper(true)
	GameFlowPageRouterScript.show_page(page, entry_screen, map_screen, scene_screen, demo_screen, practice_screen)
	_apply_toolbox_lock_state()
	if page == "entry":
		entry_screen.focus_name_input()
	if page == "demo":
		_ensure_demo_toolbox_helper()

func _apply_toolbox_lock_state() -> void:
	var practice_locked: bool = _toolbox_helper_pid > 0 and _toolbox_context == "challenge"
	practice_screen.set_toolbox_lock(practice_locked, TOOLBOX_LOCK_MESSAGE if practice_locked else "")

func _build_toolbox_launch_request(level_id: String, context: String) -> Dictionary:
	var python_path: String = _resolve_project_path(DEFAULT_TOOLBOX_PYTHON_REL_PATH)
	if not FileAccess.file_exists(python_path):
		_set_workspace_status(context, "Python launcher not found: %s" % python_path)
		return {}
	var html_path: String = _resolve_project_path(TOOLBOX_HTML_REL_PATH)
	if not FileAccess.file_exists(html_path):
		_set_workspace_status(context, "Blockly HTML not found: %s" % html_path)
		return {}

	var runtime_dir: String = ProjectSettings.globalize_path(TOOLBOX_RESULT_DIR)
	DirAccess.make_dir_recursive_absolute(runtime_dir)
	var safe_level_id: String = level_id.replace("/", "_") if level_id != "" else "level"
	var result_file: String = runtime_dir.path_join("toolbox_%s_%s.json" % [safe_level_id, str(Time.get_ticks_msec())])
	if FileAccess.file_exists(result_file):
		DirAccess.remove_absolute(result_file)
	var layout_file: String = runtime_dir.path_join("toolbox_layout_%s_%s.json" % [safe_level_id, str(Time.get_ticks_msec())])

	var args := PackedStringArray([
		"-m",
		TOOLBOX_MODULE,
		"--level-id",
		level_id,
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

func _ensure_demo_toolbox_helper() -> void:
	var demo_view: Dictionary = GameFlowMapperScript.map_game_state(_state_store.get_state()).get("demo_view", {}) if _state_store.has_state() else {}
	var current_level_id: String = str(demo_view.get("current_level_id", ""))
	if current_level_id == "":
		demo_screen.set_workspace_ready(false)
		demo_screen.set_can_convert(false)
		demo_screen.set_status("Demo workspace is unavailable until a demo level is active.")
		return
	if _toolbox_helper_pid > 0 and _toolbox_context == "demo" and _toolbox_active_level_id == current_level_id:
		demo_screen.set_workspace_ready(true)
		demo_screen.set_can_convert(true)
		_sync_toolbox_layout_file()
		return
	if _toolbox_helper_pid > 0:
		_stop_toolbox_helper(true)
	var launch_request: Dictionary = _build_toolbox_launch_request(current_level_id, "demo")
	if launch_request.is_empty():
		demo_screen.set_workspace_ready(false)
		demo_screen.set_can_convert(false)
		return
	var pid: int = OS.create_process(str(launch_request.get("python_path", "")), launch_request.get("args", PackedStringArray()), false)
	if pid <= 0:
		demo_screen.set_workspace_ready(false)
		demo_screen.set_status("Failed to launch Blockly workspace.")
		return
	_toolbox_helper_pid = pid
	_toolbox_result_file = str(launch_request.get("result_file", ""))
	_toolbox_layout_file = str(launch_request.get("layout_file", ""))
	_toolbox_last_result_token = ""
	_toolbox_last_layout_payload = ""
	_toolbox_active_level_id = current_level_id
	_toolbox_context = "demo"
	_toolbox_workspace_python_code = ""
	_toolbox_workspace_block_json = {}
	_sync_toolbox_layout_file()
	demo_screen.set_workspace_ready(true)
	demo_screen.set_can_convert(true)
	demo_screen.set_status("Blockly workspace ready. Build blocks, then convert to Python.")

func _poll_demo_conversion_timeout() -> void:
	if not _demo_conversion_pending:
		return
	if Time.get_ticks_msec() - _demo_conversion_requested_at_msec < 1500:
		return
	_demo_conversion_pending = false
	_demo_conversion_requested_at_msec = 0
	if _toolbox_workspace_python_code.strip_edges() != "":
		demo_screen.set_python_preview(_toolbox_workspace_python_code)
		demo_screen.set_status("Status: Python preview updated.")
		return
	demo_screen.clear_python_preview()
	demo_screen.set_status("No convertible Python yet. Make sure the blocks are connected as a valid program.")
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
	var is_visible: bool = practice_screen.visible and practice_screen.is_visible_in_tree()
	if _toolbox_context == "demo":
		target_control = demo_screen.get_workspace_target_control()
		is_visible = demo_screen.visible and demo_screen.is_visible_in_tree()
	return WindowAlignmentHelperScript.build_layout_payload(
		_toolbox_active_level_id,
		owner_title,
		int(DisplayServer.window_get_native_handle(DisplayServer.WINDOW_HANDLE)),
		target_control,
		is_visible
	)

func _handle_toolbox_result(payload: Dictionary) -> void:
	var status: String = str(payload.get("status", ""))
	var message: String = str(payload.get("message", ""))
	if status == "toolbox_status":
		_set_workspace_status(_toolbox_context, message)
		return
	if status == "toolbox_error":
		if _toolbox_context == "demo":
			demo_screen.clear_python_preview()
			if _demo_conversion_pending:
				_demo_conversion_pending = false
				_demo_conversion_requested_at_msec = 0
		_set_workspace_status(_toolbox_context, message)
		return
	if status == "toolbox_sync":
		var level_id: String = str(payload.get("level_id", ""))
		if level_id != _toolbox_active_level_id:
			return
		var python_code: String = str(payload.get("python_code", ""))
		var block_json: Variant = payload.get("block_json", {})
		_toolbox_workspace_python_code = python_code
		if block_json is Dictionary:
			_toolbox_workspace_block_json = block_json
		else:
			_toolbox_workspace_block_json = {}
		if _toolbox_context == "demo":
			demo_screen.set_workspace_ready(true)
			if _demo_conversion_pending:
				if _toolbox_workspace_python_code.strip_edges() == "":
					demo_screen.clear_python_preview()
					demo_screen.set_status("No blocks in workspace yet. Add blocks, then convert again.")
				else:
					demo_screen.set_python_preview(_toolbox_workspace_python_code)
					demo_screen.set_status("Status: Python preview updated.")
				_demo_conversion_pending = false
		_demo_conversion_requested_at_msec = 0
		return
	if status == "toolbox_closed":
		_stop_toolbox_helper(false)

func _stop_toolbox_helper(force_kill: bool) -> void:
	var previous_context: String = _toolbox_context
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
	_toolbox_context = ""
	_demo_conversion_pending = false
	_demo_conversion_requested_at_msec = 0
	practice_screen.set_toolbox_lock(false)
	demo_screen.set_workspace_ready(false)
	if previous_context == "challenge" and _current_page == "challenge":
		practice_screen.set_status("Practice flow ready")
		practice_screen.focus_code_editor()
	elif previous_context == "demo" and _current_page == "demo":
		demo_screen.set_status("Blockly workspace closed.")

func _set_workspace_status(context: String, message: String) -> void:
	if context == "demo":
		demo_screen.set_status(message)
		return
	practice_screen.set_status(message)

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


func _send_create_profile(name: String, gender: String) -> void:
	entry_screen.set_status("Status: creating profile...")
	python_bridge_client.send_create_player_profile(name, gender)

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_stop_toolbox_helper(true)
