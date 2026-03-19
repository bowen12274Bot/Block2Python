extends RefCounted
class_name GameFlowScreenPresenter


static func render_map_view(map_screen: Control, map_view: Dictionary, _state: Dictionary, view_model: Dictionary, current_node_enterable: bool) -> void:
	map_screen.show_map(map_view)
	map_screen.set_status("Status: response ok=true")
	var can_advance: bool = _can_advance_from_view_model(view_model)
	map_screen.set_can_advance(can_advance)
	map_screen.set_current_node_enterable(current_node_enterable)
	map_screen.set_note(_map_note_for_state(can_advance, current_node_enterable))


static func render_flow_views(scene_screen: Control, challenge_screen: Control, view_model: Dictionary, feedback_view: Dictionary) -> void:
	var action_view: Variant = view_model.get("action_view", {})
	var can_advance: bool = false
	var can_submit: bool = false
	if action_view is Dictionary:
		can_advance = bool(action_view.get("can_advance", false))
		can_submit = bool(action_view.get("can_submit", false))

	scene_screen.show_scene(view_model.get("scene_view", {}))
	scene_screen.set_status("Status: scene flow ready")
	scene_screen.set_can_advance(can_advance)
	challenge_screen.show_challenge(view_model.get("challenge_view", {}))
	challenge_screen.show_feedback(feedback_view)
	challenge_screen.set_status("Challenge flow ready")
	challenge_screen.set_can_submit(can_submit)


static func apply_error_ui(map_screen: Control, scene_screen: Control, challenge_screen: Control, map_status: String, map_note: String, feedback_title: String, feedback_body: String) -> void:
	map_screen.set_status(map_status)
	map_screen.set_note(map_note)
	scene_screen.set_status(map_status)
	challenge_screen.set_status(map_status)
	challenge_screen.show_feedback({
		"title": feedback_title,
		"body": feedback_body,
	})


static func can_advance_from_view_model(view_model: Dictionary) -> bool:
	return _can_advance_from_view_model(view_model)


static func _can_advance_from_view_model(view_model: Dictionary) -> bool:
	var action_view_variant: Variant = view_model.get("action_view", {})
	if action_view_variant is Dictionary:
		return bool(action_view_variant.get("can_advance", false))
	return false


static func _map_note_for_state(can_advance: bool, can_open: bool) -> String:
	if can_open:
		return "Open Current Node to enter the active story or challenge page. The map now reflects live route state."
	if can_advance:
		return "Current route step has no standalone page yet. Use Advance to move forward."
	return "Current route step cannot be opened as a separate page."
