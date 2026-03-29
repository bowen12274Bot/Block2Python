extends RefCounted
class_name FlowToolboxController

const DEFAULT_TOOLBOX_PYTHON_REL_PATH := "../.venv/Scripts/python.exe"
const TOOLBOX_HTML_REL_PATH := "../assets/blockly/index.html"
const TOOLBOX_MODULE := "block2python.clients.toolbox_window"
const TOOLBOX_LOCK_MESSAGE := "Toolbox is active. Close toolbox to resume Python editing."
const TOOLBOX_RESULT_DIR := "user://toolbox_runtime"

const WindowAlignmentHelperScript = preload("res://scripts/bridge/window_alignment.gd")
const WindowLayoutSyncScript = preload("res://scripts/bridge/window_layout_sync.gd")

var _owner: Control
var _demo_screen: Control
var _practice_screen: Control

var _helper_pid: int = -1
var _result_file: String = ""
var _layout_file: String = ""
var _last_result_token: String = ""
var _last_layout_payload: String = ""
var _active_level_id: String = ""
var _workspace_python_code: String = ""
var _workspace_block_json: Dictionary = {}
var _context: String = ""
var _current_page: String = ""
var _toolbox_visible_requested: bool = false
var _workspace_reset_revision: int = 0
var _demo_conversion_pending: bool = false
var _demo_conversion_requested_at_msec: int = 0


func setup(owner: Control, demo_screen: Control, practice_screen: Control) -> void:
	_owner = owner
	_demo_screen = demo_screen
	_practice_screen = practice_screen


func process_tick() -> void:
	_poll_helper()
	_poll_demo_conversion_timeout()


func prewarm_helper() -> void:
	if not _ensure_helper_running("toolbox", ""):
		return
	_toolbox_visible_requested = false
	_sync_layout_file()


func request_demo_convert() -> void:
	var demo_view: Dictionary = _demo_screen.current_view()
	var current_level_id: String = str(demo_view.get("current_level_id", ""))
	if current_level_id == "":
		_demo_screen.set_status("Demo workspace is unavailable until a demo level is active.")
		_demo_screen.set_workspace_ready(false)
		return
	if not _ensure_helper_running(current_level_id, "demo"):
		_demo_screen.set_workspace_ready(false)
		return
	_sync_demo_context(demo_view, false, true)
	_demo_conversion_pending = true
	_demo_conversion_requested_at_msec = Time.get_ticks_msec()
	_demo_screen.set_workspace_ready(true)
	_demo_screen.set_status("Status: requesting latest block conversion...")
	if _workspace_python_code.strip_edges() != "":
		_demo_screen.set_python_preview(_workspace_python_code)


func ensure_demo_helper(demo_view: Dictionary) -> void:
	var current_level_id: String = str(demo_view.get("current_level_id", ""))
	if current_level_id == "":
		_demo_screen.set_workspace_ready(false)
		_demo_screen.set_can_convert(false)
		_demo_screen.set_status("Demo workspace is unavailable until a demo level is active.")
		return
	if not _ensure_helper_running(current_level_id, "demo"):
		_demo_screen.set_workspace_ready(false)
		_demo_screen.set_can_convert(false)
		return
	_demo_screen.set_workspace_ready(true)
	_demo_screen.set_can_convert(true)
	if _workspace_python_code.strip_edges() == "":
		_demo_screen.set_status("Blockly workspace ready. Build blocks, then convert to Python.")


func toggle_challenge_helper(practice_view: Dictionary, current_page: String) -> void:
	var current_level_id: String = str(practice_view.get("current_level_id", ""))
	if current_level_id == "":
		_practice_screen.set_status("Toolbox is only available when a practice level is active.")
		return
	if not bool(practice_view.get("toolbox_allowed", false)):
		_practice_screen.set_status("Toolbox is only available in practice challenges.")
		return
	if _toolbox_visible_requested and _context == "challenge":
		_hide_toolbox()
		_practice_screen.set_status("Toolbox closed.")
		_practice_screen.focus_code_editor()
		return
	if not _ensure_helper_running(current_level_id, "challenge"):
		_practice_screen.set_status("Failed to launch toolbox window.")
		return
	var needs_reset: bool = _should_reset_for_transition("challenge", current_level_id)
	_context = "challenge"
	_active_level_id = current_level_id
	if needs_reset:
		_request_workspace_reset()
	_show_toolbox()
	_practice_screen.set_toolbox_lock(true, TOOLBOX_LOCK_MESSAGE)


func handle_page_changed(page: String, demo_view: Dictionary) -> void:
	var previous_page: String = _current_page
	_current_page = page
	if page == "demo":
		_sync_demo_context(demo_view, previous_page != "demo", false)
	elif page == "challenge":
		_sync_practice_context(_practice_screen.current_view(), previous_page != "challenge")
	else:
		if previous_page == "demo" or previous_page == "challenge":
			_request_workspace_reset()
			_hide_toolbox()
			_context = ""
			_active_level_id = ""
	apply_lock_state()


func apply_lock_state() -> void:
	var practice_locked: bool = _helper_pid > 0 and _context == "challenge" and _toolbox_visible_requested
	_practice_screen.set_toolbox_lock(practice_locked, TOOLBOX_LOCK_MESSAGE if practice_locked else "")


func is_challenge_workspace_active() -> bool:
	return _helper_pid > 0 and _context == "challenge" and not _workspace_block_json.is_empty()


func workspace_python_code() -> String:
	return _workspace_python_code


func workspace_block_json() -> Dictionary:
	return _workspace_block_json.duplicate(true)


func debug_state_lines() -> Array[String]:
	return [
		"toolbox_helper_pid=%s" % str(_helper_pid),
		"toolbox_context=%s" % _context,
		"toolbox_visible=%s" % str(_toolbox_visible_requested),
		"toolbox_reset_revision=%s" % str(_workspace_reset_revision),
	]


func stop_helper(force_kill: bool, current_page: String) -> void:
	var previous_context: String = _context
	if _helper_pid > 0 and force_kill:
		OS.kill(_helper_pid)
	_helper_pid = -1
	_result_file = ""
	_layout_file = ""
	_last_result_token = ""
	_last_layout_payload = ""
	_active_level_id = ""
	_workspace_python_code = ""
	_workspace_block_json = {}
	_context = ""
	_toolbox_visible_requested = false
	_demo_conversion_pending = false
	_demo_conversion_requested_at_msec = 0
	_practice_screen.set_toolbox_lock(false)
	_demo_screen.set_workspace_ready(false)
	if previous_context == "challenge" and current_page == "challenge":
		_practice_screen.set_status("Practice flow ready")
		_practice_screen.focus_code_editor()
	elif previous_context == "demo" and current_page == "demo":
		_demo_screen.set_status("Blockly workspace closed.")


func _ensure_helper_running(level_id: String, context: String) -> bool:
	if _helper_pid > 0:
		return true
	var launch_request: Dictionary = _build_launch_request(level_id if level_id != "" else "toolbox", context)
	if launch_request.is_empty():
		return false
	var pid: int = OS.create_process(str(launch_request.get("python_path", "")), launch_request.get("args", PackedStringArray()), false)
	if pid <= 0:
		return false
	_apply_launch_request(pid, launch_request, level_id, context)
	_workspace_python_code = ""
	_workspace_block_json = {}
	return true


func _show_toolbox() -> void:
	_toolbox_visible_requested = true
	_sync_layout_file()
	apply_lock_state()


func _hide_toolbox() -> void:
	_toolbox_visible_requested = false
	_sync_layout_file()
	apply_lock_state()


func _request_workspace_reset() -> void:
	_workspace_reset_revision += 1
	_workspace_python_code = ""
	_workspace_block_json = {}
	_demo_conversion_pending = false
	_demo_conversion_requested_at_msec = 0
	_demo_screen.clear_python_preview()
	_sync_layout_file()


func _should_reset_for_transition(context: String, level_id: String) -> bool:
	if _helper_pid <= 0:
		return false
	if _context == "":
		return false
	if _context != context:
		return true
	return _active_level_id != level_id


func _sync_demo_context(demo_view: Dictionary, entering_page: bool, force_show: bool) -> void:
	var current_level_id: String = str(demo_view.get("current_level_id", ""))
	if current_level_id == "":
		_demo_screen.set_workspace_ready(false)
		_demo_screen.set_can_convert(false)
		if _context == "demo":
			_request_workspace_reset()
			_hide_toolbox()
			_context = ""
			_active_level_id = ""
		return
	ensure_demo_helper(demo_view)
	var needs_reset: bool = _should_reset_for_transition("demo", current_level_id)
	_context = "demo"
	_active_level_id = current_level_id
	if needs_reset:
		_request_workspace_reset()
	if entering_page or force_show:
		_toolbox_visible_requested = true
	_sync_layout_file()


func _sync_practice_context(practice_view: Dictionary, entering_page: bool) -> void:
	var current_level_id: String = str(practice_view.get("current_level_id", ""))
	if current_level_id == "":
		if _context == "challenge":
			_request_workspace_reset()
			_hide_toolbox()
			_context = ""
			_active_level_id = ""
		return
	if _helper_pid > 0:
		var needs_reset: bool = _should_reset_for_transition("challenge", current_level_id)
		_context = "challenge"
		_active_level_id = current_level_id
		if needs_reset:
			_request_workspace_reset()
		_sync_layout_file()
	else:
		_context = "challenge"
		_active_level_id = current_level_id
	if entering_page:
		_toolbox_visible_requested = false


func _apply_launch_request(pid: int, launch_request: Dictionary, current_level_id: String, context: String) -> void:
	_helper_pid = pid
	_result_file = str(launch_request.get("result_file", ""))
	_layout_file = str(launch_request.get("layout_file", ""))
	_last_result_token = ""
	_last_layout_payload = ""
	_active_level_id = current_level_id
	_context = context


func _build_launch_request(level_id: String, context: String) -> Dictionary:
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
	var helper_token: String = str(Time.get_ticks_msec())
	var result_file: String = runtime_dir.path_join("toolbox_shared_%s.json" % helper_token)
	if FileAccess.file_exists(result_file):
		DirAccess.remove_absolute(result_file)
	var layout_file: String = runtime_dir.path_join("toolbox_layout_shared_%s.json" % helper_token)

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


func _poll_demo_conversion_timeout() -> void:
	if not _demo_conversion_pending:
		return
	if Time.get_ticks_msec() - _demo_conversion_requested_at_msec < 1500:
		return
	_demo_conversion_pending = false
	_demo_conversion_requested_at_msec = 0
	if _workspace_python_code.strip_edges() != "":
		_demo_screen.set_python_preview(_workspace_python_code)
		_demo_screen.set_status("Status: Python preview updated.")
		return
	_demo_screen.clear_python_preview()
	_demo_screen.set_status("No convertible Python yet. Make sure the blocks are connected as a valid program.")


func _poll_helper() -> void:
	if _helper_pid <= 0:
		return
	_sync_layout_file()
	_poll_result_file()


func _poll_result_file() -> void:
	if _result_file == "" or not FileAccess.file_exists(_result_file):
		return
	var file := FileAccess.open(_result_file, FileAccess.READ)
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
	if token == _last_result_token:
		return
	_last_result_token = token
	_handle_result(payload)


func _sync_layout_file() -> void:
	if _layout_file == "":
		return
	var payload: Dictionary = _build_layout_payload()
	_last_layout_payload = WindowLayoutSyncScript.sync_layout_file(_layout_file, payload, _last_layout_payload)


func _build_layout_payload() -> Dictionary:
	var owner_title: String = _owner.get_window().title if _owner.get_window() != null else str(ProjectSettings.get_setting("application/config/name", "Block2Python Godot POC"))
	var target_control: Control = _practice_screen.practice_panel.get_toolbox_target_control()
	if _context == "demo":
		target_control = _demo_screen.get_workspace_target_control()
	var screen_visible: bool = target_control.is_visible_in_tree() and target_control.visible
	var payload: Dictionary = WindowAlignmentHelperScript.build_layout_payload(
		_active_level_id,
		owner_title,
		int(DisplayServer.window_get_native_handle(DisplayServer.WINDOW_HANDLE)),
		target_control,
		screen_visible and _toolbox_visible_requested
	)
	payload["toolbox_block_ids"] = _current_toolbox_block_ids()
	payload["reset_token"] = _workspace_reset_revision
	payload["context"] = _context
	return payload


func _current_toolbox_block_ids() -> Array[String]:
	if _context == "demo":
		return _current_demo_toolbox_block_ids()
	if _context == "challenge":
		return _current_practice_toolbox_block_ids()
	return []


func _current_demo_toolbox_block_ids() -> Array[String]:
	var demo_view: Dictionary = _demo_screen.current_view()
	var block_ids: Array[String] = []
	var raw_block_ids: Variant = demo_view.get("toolbox_block_ids", [])
	if raw_block_ids is Array:
		for block_id_variant in raw_block_ids:
			block_ids.append(str(block_id_variant))
	return block_ids


func _current_practice_toolbox_block_ids() -> Array[String]:
	var practice_view: Dictionary = _practice_screen.current_view()
	var block_ids: Array[String] = []
	var raw_block_ids: Variant = practice_view.get("toolbox_block_ids", [])
	if raw_block_ids is Array:
		for block_id_variant in raw_block_ids:
			block_ids.append(str(block_id_variant))
	return block_ids


func _handle_result(payload: Dictionary) -> void:
	var status: String = str(payload.get("status", ""))
	var message: String = str(payload.get("message", ""))
	if status == "toolbox_status":
		_set_workspace_status(_context, message)
		return
	if status == "toolbox_error":
		if _context == "demo":
			_demo_screen.clear_python_preview()
			if _demo_conversion_pending:
				_demo_conversion_pending = false
				_demo_conversion_requested_at_msec = 0
		_set_workspace_status(_context, message)
		return
	if status == "toolbox_sync":
		var level_id: String = str(payload.get("level_id", ""))
		if level_id != _active_level_id:
			return
		var python_code: String = str(payload.get("python_code", ""))
		var block_json: Variant = payload.get("block_json", {})
		_workspace_python_code = python_code
		_workspace_block_json = block_json if block_json is Dictionary else {}
		if _context == "demo":
			_demo_screen.set_workspace_ready(true)
			if _demo_conversion_pending:
				if _workspace_python_code.strip_edges() == "":
					_demo_screen.clear_python_preview()
					_demo_screen.set_status("No blocks in workspace yet. Add blocks, then convert again.")
				else:
					_demo_screen.set_python_preview(_workspace_python_code)
					_demo_screen.set_status("Status: Python preview updated.")
				_demo_conversion_pending = false
		_demo_conversion_requested_at_msec = 0
		return
	if status == "toolbox_closed":
		_hide_toolbox()
		if _current_page == "challenge":
			_practice_screen.set_status("Toolbox closed.")
			_practice_screen.focus_code_editor()
		elif _current_page == "demo":
			_demo_screen.set_status("Blockly workspace hidden.")


func _set_workspace_status(context: String, message: String) -> void:
	if context == "demo":
		_demo_screen.set_status(message)
		return
	_practice_screen.set_status(message)


func _resolve_project_path(relative_path: String) -> String:
	return ProjectSettings.globalize_path("res://%s" % relative_path)
