extends Node
class_name PythonBridgeClient

signal bridge_started()
signal bridge_failed(message: String)
signal response_received(response: Dictionary)

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


func send_request(payload: Dictionary) -> void:
	if not is_running():
		_fail_bridge("Bridge is not running")
		return

	var request_json: String = JSON.stringify(payload)
	_stdio.store_line(request_json)
	_stdio.flush()

	var response_line: String = _stdio.get_line()
	if _stdio.get_error() != OK:
		var stderr_text: String = _read_stderr_text()
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
