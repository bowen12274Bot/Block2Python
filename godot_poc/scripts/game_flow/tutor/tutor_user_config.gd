extends RefCounted
class_name TutorUserConfig

const CONFIG_PATH := "user://tutor_config.json"
const DEFAULT_PROVIDER := "temple"
const DEFAULT_OPENAI_ENDPOINT_URL := "https://api.openai.com/v1/chat/completions"
const DEFAULT_OPENAI_MODEL := "gpt-4o-mini"
const DEFAULT_OPENAI_TIMEOUT_SEC := 30.0
const DEFAULT_LOCAL_OLLAMA_ENDPOINT := "http://127.0.0.1:11434/v1/chat/completions"
const DEFAULT_LOCAL_OLLAMA_MODEL := "qwen3.5:0.8b"
const DEFAULT_LOCAL_OLLAMA_TIMEOUT_SEC := 20.0
const DEFAULT_LOCAL_OLLAMA_API_SKILL_MODEL := "qwen3.5:9b"
const DEFAULT_LOCAL_OLLAMA_API_SKILL_TIMEOUT_SEC := 45.0
const DEFAULT_ENDPOINT_URL := DEFAULT_LOCAL_OLLAMA_ENDPOINT
const DEFAULT_MODEL := DEFAULT_LOCAL_OLLAMA_MODEL
const DEFAULT_TIMEOUT_SEC := DEFAULT_LOCAL_OLLAMA_TIMEOUT_SEC


static func default_config() -> Dictionary:
	return {
		"provider": DEFAULT_PROVIDER,
		"endpoint_url": DEFAULT_ENDPOINT_URL,
		"model": DEFAULT_MODEL,
		"api_key": "",
		"timeout_sec": DEFAULT_TIMEOUT_SEC,
		"system_prompt": "",
	}


static func load_config() -> Dictionary:
	var defaults: Dictionary = default_config()
	if not FileAccess.file_exists(CONFIG_PATH):
		return defaults

	var file: FileAccess = FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		return defaults

	var raw_text: String = file.get_as_text()
	file.close()
	if raw_text.strip_edges() == "":
		return defaults

	var parsed: Variant = JSON.parse_string(raw_text)
	if not (parsed is Dictionary):
		return defaults

	return _normalize_config(parsed, defaults)


static func save_config(config: Dictionary) -> bool:
	var normalized: Dictionary = _normalize_config(config, default_config())
	var file: FileAccess = FileAccess.open(CONFIG_PATH, FileAccess.WRITE)
	if file == null:
		return false

	file.store_string(JSON.stringify(normalized, "\t"))
	file.flush()
	file.close()
	return true


static func provider_options(config: Dictionary) -> Dictionary:
	var normalized: Dictionary = _normalize_config(config, default_config())
	return {
		"endpoint_url": normalized.get("endpoint_url", DEFAULT_ENDPOINT_URL),
		"model": normalized.get("model", DEFAULT_MODEL),
		"api_key": normalized.get("api_key", ""),
		"timeout_sec": float(normalized.get("timeout_sec", DEFAULT_TIMEOUT_SEC)),
		"system_prompt": normalized.get("system_prompt", ""),
	}


static func _normalize_config(raw: Dictionary, defaults: Dictionary) -> Dictionary:
	var merged: Dictionary = defaults.duplicate(true)

	var provider_raw: Variant = raw.get("provider", merged.get("provider", DEFAULT_PROVIDER))
	if provider_raw is String and String(provider_raw).strip_edges() != "":
		merged["provider"] = _normalize_provider_name(String(provider_raw).strip_edges().to_lower())

	var endpoint_raw: Variant = raw.get("endpoint_url", merged.get("endpoint_url", DEFAULT_ENDPOINT_URL))
	if endpoint_raw is String:
		merged["endpoint_url"] = String(endpoint_raw).strip_edges()

	var model_raw: Variant = raw.get("model", merged.get("model", DEFAULT_MODEL))
	if model_raw is String:
		merged["model"] = String(model_raw).strip_edges()

	var api_key_raw: Variant = raw.get("api_key", merged.get("api_key", ""))
	if api_key_raw is String:
		merged["api_key"] = String(api_key_raw).strip_edges()

	var timeout_raw: Variant = raw.get("timeout_sec", merged.get("timeout_sec", DEFAULT_TIMEOUT_SEC))
	if timeout_raw is float or timeout_raw is int:
		var timeout_value: float = float(timeout_raw)
		if timeout_value > 0:
			merged["timeout_sec"] = timeout_value

	var system_prompt_raw: Variant = raw.get("system_prompt", merged.get("system_prompt", ""))
	if system_prompt_raw is String:
		merged["system_prompt"] = String(system_prompt_raw).strip_edges()

	if merged.get("provider", DEFAULT_PROVIDER) == "temple":
		if String(merged.get("endpoint_url", "")).strip_edges() == "" or String(merged.get("endpoint_url", "")).strip_edges() == DEFAULT_OPENAI_ENDPOINT_URL:
			merged["endpoint_url"] = DEFAULT_LOCAL_OLLAMA_ENDPOINT
		if String(merged.get("model", "")).strip_edges() == "" or String(merged.get("model", "")).strip_edges() == DEFAULT_OPENAI_MODEL:
			merged["model"] = DEFAULT_LOCAL_OLLAMA_MODEL
		if float(merged.get("timeout_sec", DEFAULT_TIMEOUT_SEC)) <= 0.0:
			merged["timeout_sec"] = DEFAULT_LOCAL_OLLAMA_TIMEOUT_SEC

	if merged.get("provider", DEFAULT_PROVIDER) == "api_skill":
		if String(merged.get("endpoint_url", "")).strip_edges() == "" or String(merged.get("endpoint_url", "")).strip_edges() == DEFAULT_OPENAI_ENDPOINT_URL:
			merged["endpoint_url"] = DEFAULT_LOCAL_OLLAMA_ENDPOINT
		if String(merged.get("model", "")).strip_edges() == "" or String(merged.get("model", "")).strip_edges() == DEFAULT_OPENAI_MODEL or String(merged.get("model", "")).strip_edges() == DEFAULT_LOCAL_OLLAMA_MODEL:
			merged["model"] = DEFAULT_LOCAL_OLLAMA_API_SKILL_MODEL
		if float(merged.get("timeout_sec", DEFAULT_TIMEOUT_SEC)) <= 0.0:
			merged["timeout_sec"] = DEFAULT_LOCAL_OLLAMA_API_SKILL_TIMEOUT_SEC

	return merged


static func _normalize_provider_name(provider: String) -> String:
	match provider:
		"stub":
			return "stub"
		"temple", "template", "local":
			return "temple"
		"api_skill", "api+skill", "api-skill", "openai_compatible":
			return "api_skill"
		_:
			return DEFAULT_PROVIDER
