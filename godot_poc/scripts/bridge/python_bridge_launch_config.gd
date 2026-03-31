extends RefCounted
class_name PythonBridgeLaunchConfig


static func build(project_resolver: Callable, python_rel_path: String, pythonpath_rel_path: String, wasm_rel_path: String, levels_rel_path: String, game_content_rel_path: String, teaching_skills_rel_path: String, bridge_log_rel_path: String, tutor_thinking_log_rel_path: String, wasmtime_candidate_rel_paths: PackedStringArray) -> Dictionary:
	var python_abs: String = resolve_project_path(project_resolver, python_rel_path)
	if not FileAccess.file_exists(python_abs):
		return {}

	var pythonpath_abs: String = resolve_project_path(project_resolver, pythonpath_rel_path)
	var wasm_abs: String = resolve_project_path(project_resolver, wasm_rel_path)
	var levels_abs: String = resolve_project_path(project_resolver, levels_rel_path)
	var game_content_abs: String = resolve_project_path(project_resolver, game_content_rel_path)
	var teaching_skills_abs: String = resolve_project_path(project_resolver, teaching_skills_rel_path)
	var bridge_log_abs: String = resolve_project_path(project_resolver, bridge_log_rel_path)
	var tutor_thinking_log_abs: String = resolve_project_path(project_resolver, tutor_thinking_log_rel_path)
	var args: PackedStringArray = PackedStringArray([
		"-m",
		"block2python.integration.bridge_stdio.server",
		"--levels-dir",
		levels_abs,
		"--game-content-dir",
		game_content_abs,
		"--teaching-skills-dir",
		teaching_skills_abs,
		"--log-file",
		bridge_log_abs,
		"--thinking-log-file",
		tutor_thinking_log_abs,
	])

	return {
		"python_path": python_abs,
		"pythonpath_path": pythonpath_abs,
		"wasm_path": wasm_abs,
		"bridge_log_path": bridge_log_abs,
		"tutor_thinking_log_path": tutor_thinking_log_abs,
		"wasmtime_bin": find_wasmtime_bin(project_resolver, wasmtime_candidate_rel_paths),
		"args": args,
	}


static func resolve_project_path(project_resolver: Callable, relative_path: String) -> String:
	return str(project_resolver.call(relative_path))


static func find_wasmtime_bin(project_resolver: Callable, candidate_rel_paths: PackedStringArray) -> String:
	for relative_path in candidate_rel_paths:
		var absolute_path: String = resolve_project_path(project_resolver, str(relative_path))
		if FileAccess.file_exists(absolute_path):
			return absolute_path
	return ""


static func apply_environment(launch_config: Dictionary) -> void:
	OS.set_environment("PYTHONPATH", str(launch_config.get("pythonpath_path", "")))
	OS.set_environment("PYTHONUTF8", "1")
	OS.set_environment("PYTHONIOENCODING", "utf-8")
	OS.set_environment("BLOCK2PYTHON_WASM_PATH", str(launch_config.get("wasm_path", "")))
	OS.set_environment("BLOCK2PYTHON_WASM_CODE_MODE", "stdin")
	OS.set_environment("BLOCK2PYTHON_BRIDGE_LOG_PATH", str(launch_config.get("bridge_log_path", "")))
	OS.set_environment("BLOCK2PYTHON_TUTOR_THINKING_LOG_PATH", str(launch_config.get("tutor_thinking_log_path", "")))

	var wasmtime_bin: String = str(launch_config.get("wasmtime_bin", ""))
	if wasmtime_bin != "":
		OS.set_environment("BLOCK2PYTHON_WASMTIME_BIN", wasmtime_bin)
