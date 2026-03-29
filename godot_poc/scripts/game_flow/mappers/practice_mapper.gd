extends RefCounted
class_name GameFlowPracticeMapper


static func build_practice_view(state: Dictionary) -> Dictionary:
	var practice_title: String = "Practice"
	var practice_view: Dictionary = {
		"title": practice_title,
		"group_id": "",
		"level_id": "",
		"level_title": "",
		"prompt": "",
		"progress_current": 0,
		"progress_total": 0,
		"progress_label": "Progress: --",
		"is_review_mode": false,
		"toolbox_allowed": false,
		"toolbox_used": false,
		"toolbox_block_ids": [],
		"can_run": false,
		"can_submit": false,
		"can_next": false,
		"challenge_type": "",
		"mission_text": "No mission loaded yet.",
		"battery_percent": 0,
		"battery_threshold_percent": 80,
		"assistant_messages": [],
		"assistant_chat_text": "Byte: Practice assistant is standing by.",
		"toolkit_hint": "Open the toolkit when you need help exploring a block-based solution.",
		"current_level_id": "",
		"current_level_title": "",
		"current_level_prompt": "",
	}

	var practice: Variant = state.get("practice", null)
	if practice is Dictionary:
		practice_view["challenge_type"] = str(practice.get("challenge_type", ""))
		practice_view["group_id"] = str(practice.get("group_id", ""))
		practice_view["level_id"] = str(practice.get("level_id", practice.get("current_level_id", "")))
		practice_view["level_title"] = str(practice.get("level_title", practice.get("current_level_title", "")))
		practice_view["prompt"] = str(practice.get("prompt", practice.get("current_level_prompt", "")))
		practice_view["progress_current"] = int(practice.get("progress_current", 0))
		practice_view["progress_total"] = int(practice.get("progress_total", 0))
		practice_view["is_review_mode"] = bool(practice.get("is_review_mode", false))
		practice_view["toolbox_allowed"] = bool(practice.get("toolbox_allowed", false))
		practice_view["toolbox_used"] = bool(practice.get("toolbox_used", false))
		var toolbox_block_ids: Array[String] = []
		var raw_toolbox_block_ids: Variant = practice.get("toolbox_block_ids", [])
		if raw_toolbox_block_ids is Array:
			for block_id_variant in raw_toolbox_block_ids:
				toolbox_block_ids.append(str(block_id_variant))
		practice_view["toolbox_block_ids"] = toolbox_block_ids
		practice_view["can_run"] = bool(practice.get("can_run", false))
		practice_view["can_submit"] = bool(practice.get("can_submit", false))
		practice_view["can_next"] = bool(practice.get("can_next", false))
		practice_view["mission_text"] = str(practice.get("mission_text", practice_view["prompt"]))
		practice_view["battery_percent"] = int(practice.get("battery_percent", 0))
		practice_view["battery_threshold_percent"] = int(practice.get("battery_threshold_percent", 80))
		practice_view["current_level_id"] = str(practice.get("current_level_id", practice_view["level_id"]))
		practice_view["current_level_title"] = str(practice.get("current_level_title", practice_view["level_title"]))
		practice_view["current_level_prompt"] = str(practice.get("current_level_prompt", practice_view["prompt"]))
		practice_view["title"] = str(practice_view["level_title"] if practice_view["level_title"] != "" else practice_title)

		var assistant_messages: Array[String] = []
		var raw_messages: Variant = practice.get("assistant_messages", [])
		if raw_messages is Array:
			for message_variant in raw_messages:
				assistant_messages.append(str(message_variant))
		practice_view["assistant_messages"] = assistant_messages
		practice_view["assistant_chat_text"] = "\n\n".join(assistant_messages) if not assistant_messages.is_empty() else "Byte: Practice assistant is standing by."
		practice_view["toolkit_hint"] = "Tool Kit is ready for block-based runs." if bool(practice_view["toolbox_allowed"]) else "Tool Kit is unavailable for this practice level."

	var current_level_id: String = str(practice_view.get("current_level_id", ""))
	var progress_total: int = int(practice_view.get("progress_total", 0))
	var progress_current: int = int(practice_view.get("progress_current", 0))
	if progress_total > 0 and progress_current > 0:
		practice_view["progress_label"] = "Progress: %d/%d" % [progress_current, progress_total]
	elif current_level_id != "":
		practice_view["progress_label"] = "Progress: %s" % current_level_id

	var mode_value: String = str(state.get("mode", ""))
	practice_view["code_editable"] = mode_value == "challenge" and current_level_id != ""

	return practice_view


static func build_action_view(state: Dictionary) -> Dictionary:
	var raw_actions: Variant = state.get("available_actions", null)
	if raw_actions is Dictionary:
		return {
			"can_advance": bool(raw_actions.get("advance", false)),
			"can_run": bool(raw_actions.get("run", false)),
			"can_submit": bool(raw_actions.get("submit", false)),
			"can_next": bool(raw_actions.get("next_level", false)),
		}

	return {
		"can_advance": false,
		"can_run": false,
		"can_submit": false,
		"can_next": false,
	}
