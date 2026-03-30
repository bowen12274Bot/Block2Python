extends Node
class_name PythonBridgeClient

signal bridge_started()
signal bridge_failed(message: String)
signal response_received(response: Dictionary)
signal tutor_response_received(response: Dictionary, request_tag: String)
signal tutor_request_failed(message: String, request_tag: String)

const BridgeLaunchConfigScript = preload("res://scripts/bridge/python_bridge_launch_config.gd")
const DEFAULT_PYTHON_REL_PATH := "../.venv/Scripts/python.exe"
const DEFAULT_LEVELS_REL_PATH := "../assets/levels"
const DEFAULT_GAME_CONTENT_REL_PATH := "../assets/game_content"
const DEFAULT_PYTHONPATH_REL_PATH := "../src"
const DEFAULT_WASM_REL_PATH := "../assets/wasm/python.wasm"
const DEFAULT_WASMTIME_CANDIDATE_REL_PATHS := [
	"../.block2python/tools/wasmtime/wasmtime.exe",
	"../wasmtime.exe",
	"../wasmtime/wasmtime.exe",
	"../tools/wasmtime.exe",
	"../assets/wasm/wasmtime.exe",
]

@export var python_rel_path: String = DEFAULT_PYTHON_REL_PATH
@export var levels_rel_path: String = DEFAULT_LEVELS_REL_PATH
@export var game_content_rel_path: String = DEFAULT_GAME_CONTENT_REL_PATH
@export var pythonpath_rel_path: String = DEFAULT_PYTHONPATH_REL_PATH
@export var wasm_rel_path: String = DEFAULT_WASM_REL_PATH
@export var wasmtime_candidate_rel_paths: PackedStringArray = PackedStringArray(DEFAULT_WASMTIME_CANDIDATE_REL_PATHS)

var _pipe: Dictionary = {}
var _stdio: FileAccess
var _stderr: FileAccess
var _pid: int = -1
var _request_mutex: Mutex = Mutex.new()
var _async_threads: Array[Thread] = []
var _cancelled_tutor_tags: Dictionary = {}


func is_running() -> bool:
	return _stdio != null


func start_bridge() -> bool:
	if is_running():
		return true

	var launch_config: Dictionary = _build_launch_config()
	if launch_config.is_empty():
		return false

	BridgeLaunchConfigScript.apply_environment(launch_config)
	_pipe = OS.execute_with_pipe(
		str(launch_config.get("python_path", "")),
		launch_config.get("args", PackedStringArray()),
		true
	)
	if _pipe.is_empty():
		_fail_bridge("Failed to start bridge process")
		return false

	_stdio = _pipe.get("stdio")
	_stderr = _pipe.get("stderr")
	_pid = int(_pipe.get("pid", -1))
	bridge_started.emit()
	return true


func send_reset() -> void:
	send_request({
		"command": "reset",
	})


func send_advance() -> void:
	send_request({
		"action": {
			"action_type": "advance",
			"payload": {},
		},
	})


func send_run_level(python_code: String) -> void:
	send_request({
		"action": {
			"action_type": "run_level",
			"payload": {
				"python_code": python_code,
				"block_json": null,
			},
		},
	})


func send_next_level() -> void:
	send_request({
		"action": {
			"action_type": "next_level",
			"payload": {},
		},
	})


func send_submit_level(python_code: String) -> void:
	send_request({
		"action": {
			"action_type": "submit_level",
			"payload": {
				"python_code": python_code,
				"block_json": null,
			},
		},
	})


func send_verify_toolbox_level(python_code: String, block_json: Dictionary) -> void:
	send_request({
		"action": {
			"action_type": "verify_toolbox_level",
			"payload": {
				"python_code": python_code,
				"block_json": block_json,
			},
		},
	})


func send_tutor_reply(payload: Dictionary) -> void:
	send_request({
		"command": "tutor_reply",
		"payload": payload,
	})


func send_confirm_toolbox_open() -> void:
	send_request({
		"action": {
			"action_type": "confirm_toolbox_open",
			"payload": {},
		},
	})


func send_tutor_reply_async(payload: Dictionary, request_tag: String = "") -> void:
	_send_tutor_request_async(
		{
			"command": "tutor_reply",
			"payload": payload,
		},
		request_tag
	)


func cancel_tutor_request(request_tag: String) -> void:
	var normalized_tag: String = request_tag.strip_edges()
	if normalized_tag == "":
		return
	_cancelled_tutor_tags[normalized_tag] = true


func send_start_group_story(group_id: String) -> void:
	send_request({
		"action": {
			"action_type": "start_group_story",
			"payload": {
				"group_id": group_id,
			},
		},
	})


func send_start_group_demo(group_id: String) -> void:
	send_request({
		"action": {
			"action_type": "start_group_demo",
			"payload": {
				"group_id": group_id,
			},
		},
	})


func send_start_group_practice(group_id: String) -> void:
	send_request({
		"action": {
			"action_type": "start_group_practice",
			"payload": {
				"group_id": group_id,
			},
		},
	})


func send_create_player_profile(name: String, gender: String) -> void:
	send_request({
		"action": {
			"action_type": "create_player_profile",
			"payload": {
				"name": name,
				"gender": gender,
			},
		},
	})


func send_complete_intro() -> void:
	send_request({
		"action": {
			"action_type": "complete_intro",
			"payload": {},
		},
	})


func send_request(payload: Dictionary) -> void:
	if not is_running():
		_fail_bridge("Bridge is not running")
		return

	var request_json: String = JSON.stringify(payload)
	var response_line: String = ""
	var stderr_text: String = ""
	var read_error: int = OK

	_request_mutex.lock()
	if _stdio == null:
		_request_mutex.unlock()
		_fail_bridge("Bridge is not running")
		return
	_stdio.store_line(request_json)
	_stdio.flush()

	response_line = _stdio.get_line()
	read_error = _stdio.get_error()
	if read_error != OK:
		stderr_text = _read_stderr_text_locked()
	_request_mutex.unlock()

	if read_error != OK:
		_fail_bridge("Failed to read bridge response. %s" % stderr_text.strip_edges())
		return

	var parsed: Variant = JSON.parse_string(response_line)
	if not (parsed is Dictionary):
		_fail_bridge("Bridge returned non-object JSON: %s" % response_line)
		return

	response_received.emit(parsed)


func stop_bridge() -> void:
	if _pid > 0:
		OS.kill(_pid)
	_wait_async_threads()
	_clear_process_state()


func _build_launch_config() -> Dictionary:
	var launch_config: Dictionary = BridgeLaunchConfigScript.build(
		Callable(self, "_resolve_project_path"),
		python_rel_path,
		pythonpath_rel_path,
		wasm_rel_path,
		levels_rel_path,
		game_content_rel_path,
		wasmtime_candidate_rel_paths
	)
	if not launch_config.is_empty():
		return launch_config

	var python_abs: String = _resolve_project_path(python_rel_path)
	_fail_bridge("Python not found: %s" % python_abs)
	return {}


func _resolve_project_path(relative_path: String) -> String:
	return ProjectSettings.globalize_path("res://%s" % relative_path)


func _read_stderr_text() -> String:
	if _stderr == null or _stderr.eof_reached():
		return ""
	return _stderr.get_as_text()


func _read_stderr_text_locked() -> String:
	if _stderr == null or _stderr.eof_reached():
		return ""
	return _stderr.get_as_text()


func _send_tutor_request_async(payload: Dictionary, request_tag: String) -> void:
	if not is_running():
		_emit_tutor_failure("Bridge is not running", request_tag.strip_edges())
		return

	var request_json: String = JSON.stringify(payload)
	var normalized_tag: String = request_tag.strip_edges()
	var worker: Thread = Thread.new()
	var start_error: int = worker.start(
		Callable(self, "_thread_send_tutor_request").bind(request_json, normalized_tag)
	)
	if start_error != OK:
		_emit_tutor_failure("Failed to start tutor request thread", normalized_tag)
		return

	_async_threads.append(worker)


func _thread_send_tutor_request(request_json: String, request_tag: String) -> void:
	var response_line: String = ""
	var stderr_text: String = ""
	var read_error: int = OK

	_request_mutex.lock()
	if _stdio == null:
		_request_mutex.unlock()
		call_deferred("_emit_tutor_failure", "Bridge is not running", request_tag)
		call_deferred("_cleanup_async_threads")
		return

	_stdio.store_line(request_json)
	_stdio.flush()

	response_line = _stdio.get_line()
	read_error = _stdio.get_error()
	if read_error != OK:
		stderr_text = _read_stderr_text_locked()
	_request_mutex.unlock()

	if read_error != OK:
		call_deferred("_emit_tutor_failure", "Failed to read tutor response. %s" % stderr_text.strip_edges(), request_tag)
		call_deferred("_cleanup_async_threads")
		return

	var parsed: Variant = JSON.parse_string(response_line)
	if not (parsed is Dictionary):
		call_deferred("_emit_tutor_failure", "Bridge returned non-object JSON: %s" % response_line, request_tag)
		call_deferred("_cleanup_async_threads")
		return

	call_deferred("_emit_tutor_response", parsed, request_tag)
	call_deferred("_cleanup_async_threads")


func _emit_tutor_response(response: Dictionary, request_tag: String) -> void:
	if _is_tutor_request_cancelled(request_tag):
		return
	tutor_response_received.emit(response, request_tag)


func _emit_tutor_failure(message: String, request_tag: String) -> void:
	if _is_tutor_request_cancelled(request_tag):
		return
	tutor_request_failed.emit(message, request_tag)


func _is_tutor_request_cancelled(request_tag: String) -> bool:
	if request_tag == "":
		return false
	if not _cancelled_tutor_tags.has(request_tag):
		return false
	_cancelled_tutor_tags.erase(request_tag)
	return true


func _cleanup_async_threads() -> void:
	var still_running: Array[Thread] = []
	for worker in _async_threads:
		if worker == null:
			continue
		if worker.is_alive():
			still_running.append(worker)
			continue
		worker.wait_to_finish()
	_async_threads = still_running


func _wait_async_threads() -> void:
	for worker in _async_threads:
		if worker == null:
			continue
		worker.wait_to_finish()
	_async_threads.clear()
	_cancelled_tutor_tags.clear()


func _clear_process_state() -> void:
	_pipe = {}
	_stdio = null
	_stderr = null
	_pid = -1


func _fail_bridge(message: String) -> void:
	bridge_failed.emit(message)


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		stop_bridge()
