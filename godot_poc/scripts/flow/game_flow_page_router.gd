extends RefCounted
class_name GameFlowPageRouter

static func resolved_page_for_state(state: Dictionary) -> String:
	if not has_created_profile(state):
		return "entry"
	if not has_completed_intro(state):
		return "scene"
	var mode_value: String = str(state.get("mode", ""))
	if mode_value == "scene" and has_scene_payload(state):
		return "scene"
	if mode_value == "challenge" and has_challenge_payload(state):
		return "challenge"
	return "map"

static func current_state_has_openable_page(state: Dictionary) -> bool:
	return has_created_profile(state) and (not has_completed_intro(state) or has_scene_payload(state) or has_challenge_payload(state))

static func show_page(page: String, entry_screen: Control, map_screen: Control, scene_screen: Control, challenge_screen: Control) -> void:
	entry_screen.visible = page == "entry"
	map_screen.visible = page == "map"
	scene_screen.visible = page == "scene"
	challenge_screen.visible = page == "challenge"

static func has_completed_intro(state: Dictionary) -> bool:
	return bool(state.get("intro_completed", false))

static func has_created_profile(state: Dictionary) -> bool:
	var profile_value: Variant = state.get("player_profile", null)
	if profile_value is Dictionary:
		return bool(profile_value.get("profile_created", false))
	return false

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
