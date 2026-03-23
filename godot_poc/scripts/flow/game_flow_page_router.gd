extends RefCounted
class_name GameFlowPageRouter

static func resolved_page_for_state(state: Dictionary) -> String:
	if not has_created_profile(state):
		return "entry"
	if not has_completed_intro(state):
		return "scene"
	var mode_value: String = str(state.get("mode", ""))
	if mode_value == "demo" and has_demo_payload(state):
		return "demo"
	if mode_value == "scene" and has_scene_payload(state):
		return "scene"
	if mode_value == "challenge" and has_practice_payload(state):
		return "challenge"
	return "map"

static func current_state_has_openable_page(state: Dictionary) -> bool:
	return has_created_profile(state) and (not has_completed_intro(state) or has_scene_payload(state) or has_demo_payload(state) or has_practice_payload(state))

static func show_page(page: String, entry_screen: Control, map_screen: Control, scene_screen: Control, demo_screen: Control, practice_screen: Control) -> void:
	entry_screen.visible = page == "entry"
	map_screen.visible = page == "map"
	scene_screen.visible = page == "scene"
	demo_screen.visible = page == "demo"
	practice_screen.visible = page == "challenge"

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

static func has_demo_payload(state: Dictionary) -> bool:
	var demo_value: Variant = state.get("demo", null)
	if demo_value is Dictionary:
		var demo_dict: Dictionary = demo_value
		return not demo_dict.is_empty()
	return false

static func has_practice_payload(state: Dictionary) -> bool:
	var practice_value: Variant = state.get("practice", null)
	if practice_value is Dictionary:
		var practice_dict: Dictionary = practice_value
		return not practice_dict.is_empty()
	return false
