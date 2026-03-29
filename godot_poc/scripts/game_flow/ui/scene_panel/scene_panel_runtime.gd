extends RefCounted
class_name ScenePanelRuntime


static func build_index_label(current_index: int, dialogue_blocks: Array[Dictionary]) -> String:
	var total_blocks: int = dialogue_blocks.size()
	if total_blocks <= 0:
		return ""
	return "%d / %d" % [current_index + 1, total_blocks]


static func dialogue_array_from_view(scene_view: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var blocks_value: Variant = scene_view.get("dialogue_blocks", [])
	if blocks_value is Array:
		for block_value in blocks_value:
			if block_value is Dictionary:
				result.append(block_value)
	if result.is_empty():
		var fallback_dialogue: Variant = scene_view.get("dialogue", {})
		if fallback_dialogue is Dictionary and not fallback_dialogue.is_empty():
			result.append(fallback_dialogue)
	return result


static func actor_view_for_side(scene_view: Dictionary, side: String, dialogue: Dictionary) -> Dictionary:
	var actor_value: Variant = dialogue.get("%s_actor" % side, {})
	if actor_value is Dictionary:
		return actor_value
	var scene_actor_value: Variant = scene_view.get("%s_actor" % side, {})
	if scene_actor_value is Dictionary:
		return scene_actor_value
	return {}


static func current_scene_view(scene_view: Dictionary, dialogue_blocks: Array[Dictionary], current_index: int, dialogue: Dictionary) -> Dictionary:
	var current_view: Dictionary = scene_view.duplicate(true)
	current_view["current_index"] = current_index
	current_view["total_blocks"] = dialogue_blocks.size()
	current_view["dialogue"] = dialogue
	current_view["left_actor"] = actor_view_for_side(scene_view, "left", dialogue)
	current_view["center_actor"] = actor_view_for_side(scene_view, "center", dialogue)
	current_view["right_actor"] = actor_view_for_side(scene_view, "right", dialogue)

	var background_view: Dictionary = {}
	var scene_background_value: Variant = scene_view.get("background", {})
	if scene_background_value is Dictionary:
		background_view = (scene_background_value as Dictionary).duplicate(true)
	background_view["background_id"] = str(dialogue.get("background_id", background_view.get("background_id", "")))
	background_view["image_path"] = str(dialogue.get("background_image_path", background_view.get("image_path", "")))
	current_view["background"] = background_view
	return current_view


static func continue_hint_text(scene_view: Dictionary, is_last_dialogue: bool) -> String:
	if is_last_dialogue:
		return "Continue"
	return str(scene_view.get("continue_hint_text", "Click to continue"))


static func dialogue_meta_text(scene_view: Dictionary, speaker_side: String, emphasis: String) -> String:
	var parts: Array[String] = []
	if speaker_side != "":
		parts.append("Speaker: %s" % speaker_side)
	if emphasis != "" and emphasis != "normal":
		parts.append("Tone: %s" % emphasis)
	var background: Variant = scene_view.get("background", {})
	if background is Dictionary:
		var background_id: String = str(background.get("background_id", ""))
		if background_id != "":
			parts.append("BG: %s" % background_id)
	return " | ".join(parts)


static func dialogue_display(scene_view: Dictionary, dialogue_value: Variant, show_dialogue_meta: bool, is_last_dialogue: bool) -> Dictionary:
	var dialogue: Dictionary = dialogue_value if dialogue_value is Dictionary else {}
	var speaker: String = str(dialogue.get("speaker", "Narrator"))
	var text: String = str(dialogue.get("text", "No dialogue available."))
	var speaker_side: String = str(dialogue.get("speaker_side", ""))
	var emphasis: String = str(dialogue.get("emphasis", "normal"))
	var meta_text: String = dialogue_meta_text(scene_view, speaker_side, emphasis)
	return {
		"speaker": speaker,
		"text": text,
		"speaker_side": speaker_side,
		"meta_text": meta_text,
		"meta_visible": show_dialogue_meta and meta_text != "",
		"continue_hint_text": continue_hint_text(scene_view, is_last_dialogue),
		"continue_hint_visible": continue_hint_text(scene_view, is_last_dialogue).strip_edges() != "",
	}


static func nameplate_visibility(speaker: String, speaker_side: String) -> Dictionary:
	var side := speaker_side if speaker_side in ["left", "center", "right"] else "left"
	var has_speaker := speaker.strip_edges() != ""
	return {
		"left_visible": has_speaker and side == "left",
		"center_visible": has_speaker and side == "center",
		"right_visible": has_speaker and side == "right",
		"speaker_text": speaker,
	}
