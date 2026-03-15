extends Node

signal bridge_started()
signal bridge_failed(message: String)
signal response_received(response: Dictionary)

const PYTHON_PATH := "../.venv/Scripts/python.exe"
const LEVELS_DIR := "../assets/levels"
const GAME_CONTENT_DIR := "../assets/game_content"
const PYTHONPATH_DIR := "../src"
const WASM_PATH := "../assets/wasm/python.wasm"
const WASMTIME_CANDIDATES := [
	"../assets/wasm/wasmtime.exe",
	"../wasmtime.exe",
	"../wasmtime/wasmtime.exe",
	"../tools/wasmtime.exe",
]

var _pipe: Dictionary = {}
var _stdio: FileAccess
var _stderr: FileAccess
var _pid: int = -1


func is_running() -> bool:
	return _stdio != null


func start_bridge() -> bool:
	if is_running():
		return true

	var python_abs: String = ProjectSettings.globalize_path("res://%s" % PYTHON_PATH)
	if not FileAccess.file_exists(python_abs):
		bridge_failed.emit("Python not found: %s" % python_abs)
		return false

	var pythonpath_abs: String = ProjectSettings.globalize_path("res://%s" % PYTHONPATH_DIR)
	var wasm_abs: String = ProjectSettings.globalize_path("res://%s" % WASM_PATH)
	OS.set_environment("PYTHONPATH", pythonpath_abs)
	OS.set_environment("BLOCK2PYTHON_WASM_PATH", wasm_abs)
	OS.set_environment("BLOCK2PYTHON_WASM_CODE_MODE", "stdin")

	var wasmtime_abs: String = _find_wasmtime_bin()
	if wasmtime_abs != "":
		OS.set_environment("BLOCK2PYTHON_WASMTIME_BIN", wasmtime_abs)

	var args: PackedStringArray = PackedStringArray([
		"-m",
		"block2python.integration.bridge_stdio.server",
		"--levels-dir",
		ProjectSettings.globalize_path("res://%s" % LEVELS_DIR),
		"--game-content-dir",
		ProjectSettings.globalize_path("res://%s" % GAME_CONTENT_DIR),
	])

	_pipe = OS.execute_with_pipe(python_abs, args, true)
	if _pipe.is_empty():
		bridge_failed.emit("Failed to start bridge process")
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


func send_request(payload: Dictionary) -> void:
	if not is_running():
		bridge_failed.emit("Bridge is not running")
		return

	var request_json: String = JSON.stringify(payload)
	_stdio.store_line(request_json)
	_stdio.flush()

	var response_line: String = _stdio.get_line()
	if _stdio.get_error() != OK:
		var stderr_text := ""
		if _stderr != null and not _stderr.eof_reached():
			stderr_text = _stderr.get_as_text()
		bridge_failed.emit("Failed to read bridge response. %s" % stderr_text.strip_edges())
		return

	var parsed: Variant = JSON.parse_string(response_line)
	if not (parsed is Dictionary):
		bridge_failed.emit("Bridge returned non-object JSON: %s" % response_line)
		return

	response_received.emit(parsed)


func stop_bridge() -> void:
	if _pid > 0:
		OS.kill(_pid)

	_pipe = {}
	_stdio = null
	_stderr = null
	_pid = -1


func _find_wasmtime_bin() -> String:
	for candidate in WASMTIME_CANDIDATES:
		var absolute_candidate: String = ProjectSettings.globalize_path("res://%s" % candidate)
		if FileAccess.file_exists(absolute_candidate):
			return absolute_candidate
	return ""


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		stop_bridge()
