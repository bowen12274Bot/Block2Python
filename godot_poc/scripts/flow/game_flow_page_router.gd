extends RefCounted
class_name GameFlowPageRouter


static func resolved_page_for_state(state: Dictionary) -> String:
	var mode_value: String = str(state.get("mode", ""))
	if mode_value == "scene" and has_scene_payload(state):
		return "scene"
	if mode_value == "challenge" and has_challenge_payload(state):
		return "challenge"
	return "map"


static func current_state_has_openable_page(state: Dictionary) -> bool:
	return has_scene_payload(state) or has_challenge_payload(state)


static func show_page(page: String, map_screen: Control, scene_screen: Control, challenge_screen: Control) -> void:
	map_screen.visible = page == "map"
	scene_screen.visible = page == "scene"
	challenge_screen.visible = page == "challenge"


static func has_scene_payload(state: Dictionary) -> bool:
	var scene_value: Variant = state.get("scene", null)
	if scene_value is Dictionary:
		var scene_dict: Dictionary = scene_value
		return not scene_dict.is_empty()
	return false


static func has_challenge_payload(state: Dictionary) -> bool:
	var challenge_value: Variant = state.get("challenge", null)
	if challenge_value is Dictionary:
		var challenge_dict: Dictionary = challenge_value
		return not challenge_dict.is_empty()
	return false
