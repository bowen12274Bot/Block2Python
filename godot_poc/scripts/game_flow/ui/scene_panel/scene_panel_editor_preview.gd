extends RefCounted
class_name ScenePanelEditorPreview


static func build_signature(config: Dictionary, visual_signature_parts: Array[String]) -> String:
	var signature_parts: Array[String] = [
		str(config.get("title", "")),
		str(config.get("speaker", "")),
		str(config.get("text", "")),
		str(config.get("speaker_side", "")),
		str(config.get("continue_hint", "")),
		str(config.get("use_shared_actor_slot", false)),
		str(config.get("shared_actor_slot", "")),
		str(config.get("show_calibration_stack", false)),
	]
	for side in ["left", "center", "right"]:
		var actor: Dictionary = actor_config(config, side)
		signature_parts.append_array([
			str(actor.get("enabled", false)),
			str(actor.get("display_name", "")),
			str(actor.get("portrait_id", "")),
			str(actor.get("expression_id", "")),
			str(actor.get("visual_state", "")),
		])
	signature_parts.append_array(visual_signature_parts)
	return "|".join(signature_parts)


static func build_scene_view(config: Dictionary) -> Dictionary:
	return {
		"title": str(config.get("title", "Opening Mission")),
		"current_index": 0,
		"dialogue_blocks": [{
			"speaker": str(config.get("speaker", "")),
			"text": str(config.get("text", "")),
			"speaker_side": str(config.get("speaker_side", "left")),
			"emphasis": "normal",
			"left_actor": build_actor(config, "left"),
			"center_actor": build_actor(config, "center"),
			"right_actor": build_actor(config, "right"),
		}],
		"continue_hint_text": str(config.get("continue_hint", "Click to continue")),
	}


static func build_actor(config: Dictionary, side: String) -> Dictionary:
	if bool(config.get("show_calibration_stack", false)):
		return {
			"display_name": "",
			"portrait_id": "",
			"expression_id": "",
			"visual_state": "hidden",
			"side": side,
		}

	var actor: Dictionary = actor_config(config, side)
	return {
		"display_name": str(actor.get("display_name", "")),
		"portrait_id": str(actor.get("portrait_id", "")),
		"expression_id": str(actor.get("expression_id", "")),
		"visual_state": str(actor.get("visual_state", "hidden")) if bool(actor.get("enabled", false)) else "hidden",
		"side": side,
	}


static func actor_config(config: Dictionary, side: String) -> Dictionary:
	var actors: Dictionary = config.get("actors", {})
	var actor_value: Variant = actors.get(side, {})
	if actor_value is Dictionary:
		return actor_value
	return {}


static func preview_definitions() -> Array[Dictionary]:
	return [
		{"node": "BytePreview", "portrait_id": "byte-default", "expression_id": "", "modulate": Color(1, 1, 1, 0.92)},
		{"node": "SystemPreview", "portrait_id": "system-default", "expression_id": "confused", "modulate": Color(1, 0.98, 0.92, 0.78)},
		{"node": "PlayerFemalePreview", "portrait_id": "player-female-default", "expression_id": "", "modulate": Color(0.96, 1, 1, 0.72)},
		{"node": "PlayerMalePreview", "portrait_id": "player-male-default", "expression_id": "", "modulate": Color(1, 0.96, 1, 0.72)},
		{"node": "BugKingPreview", "portrait_id": "bug-king-default", "expression_id": "", "modulate": Color(1, 0.94, 0.94, 0.72)},
	]


static func preview_base_side(config: Dictionary, side: String) -> String:
	if bool(config.get("show_calibration_stack", false)) and bool(config.get("use_shared_actor_slot", false)):
		var shared_actor_slot: String = str(config.get("shared_actor_slot", ""))
		if shared_actor_slot in ["left", "center", "right"]:
			return shared_actor_slot
	return side


static func nameplate_labels(config: Dictionary) -> Dictionary:
	var labels := {}
	for side in ["left", "center", "right"]:
		var actor: Dictionary = actor_config(config, side)
		labels[side] = str(actor.get("display_name", side.capitalize())) if bool(actor.get("enabled", false)) else side.capitalize()
	return labels
