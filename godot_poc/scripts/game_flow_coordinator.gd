extends Control
class_name GameFlowCoordinator

const DEFAULT_CHALLENGE_CODE := "print(3)\n"
const BridgeStateStoreScript = preload("res://scripts/bridge_state_store.gd")
const QuestMapViewModelMapperScript = preload("res://scripts/quest_map_view_model_mapper.gd")
const StateMapperScript = preload("res://scripts/state_mapper.gd")

@onready var bridge_client = $BridgeClient
@onready var map_screen = $MapScreen
@onready var scene_screen = $SceneScreen
@onready var challenge_screen = $ChallengeScreen
@onready var debug_margin: MarginContainer = $Margin
@onready var debug_panel: PanelContainer = $Margin/DebugPanel
@onready var response_text: RichTextLabel = $Margin/DebugPanel/DebugMargin/DebugRoot/ResponseText

@onready var start_bridge_button: Button = get_node_or_null("MapScreen/Margin/Scroll/Root/Buttons/StartBridgeButton")
@onready var reset_button: Button = get_node_or_null("MapScreen/Margin/Scroll/Root/Buttons/ResetButton")
@onready var map_advance_button: Button = get_node_or_null("MapScreen/Margin/Scroll/Root/Buttons/AdvanceButton")
@onready var open_node_button: Button = get_node_or_null("MapScreen/Margin/Scroll/Root/Buttons/OpenNodeButton")
@onready var debug_toggle_button: Button = get_node_or_null("MapScreen/Margin/Scroll/Root/Buttons/DebugToggleButton")

var _state_store: RefCounted
var _current_page: String = "map"


func _ready() -> void:
	_state_store = BridgeStateStoreScript.new()
	if start_bridge_button != null:
		start_bridge_button.pressed.connect(_on_start_bridge_requested)
	if reset_button != null:
		reset_button.pressed.connect(_on_reset_requested)
	if map_advance_button != null:
		map_advance_button.pressed.connect(_on_advance_requested)
	if open_node_button != null:
		open_node_button.pressed.connect(_on_open_current_node_requested)
	if debug_toggle_button != null:
		debug_toggle_button.toggled.connect(_on_debug_toggled)
	bridge_client.bridge_started.connect(_on_bridge_started)
	bridge_client.bridge_failed.connect(_on_bridge_failed)
	bridge_client.response_received.connect(_on_response_received)

	challenge_screen.initialize(DEFAULT_CHALLENGE_CODE)
	map_screen.show_map(QuestMapViewModelMapperScript.empty_map_view("Click Start Bridge, then Reset to load the current quest map."))
	map_screen.set_status("Status: idle")
	map_screen.set_note("Use Reset to load the latest quest state. Route steps now come from bridge map_route data.")
	map_screen.set_bridge_running(false)
	map_screen.set_can_advance(false)
	map_screen.set_current_node_enterable(false)
	scene_screen.show_placeholder("No scene loaded yet.")
	scene_screen.set_status("Scene flow is idle.")
	scene_screen.set_can_advance(false)
	challenge_screen.show_challenge({})
	challenge_screen.show_feedback(StateMapperScript.empty_feedback_view("Feedback will appear here."))
	challenge_screen.set_status("Challenge flow is idle.")
	challenge_screen.set_can_submit(false)
	_set_debug_visible(false)
	_show_page("map")


func _on_start_bridge_requested() -> void:
	map_screen.set_status("Status: starting bridge...")
	bridge_client.start_bridge()


func _on_reset_requested() -> void:
	map_screen.set_status("Status: requesting reset...")
	bridge_client.send_reset()


func _on_open_current_node_requested() -> void:
	if not _state_store.has_state():
		map_screen.set_note("No GameState loaded yet. Start the bridge and press Reset first.")
		return

	var state: Dictionary = _state_store.get_state()
	if _has_scene_payload(state):
		_show_page("scene")
		return
	if _has_challenge_payload(state):
		_show_page("challenge")
		return

	var action_view_variant: Variant = StateMapperScript.map_game_state(state).get("action_view", {})
	var can_advance: bool = false
	if action_view_variant is Dictionary:
		can_advance = bool(action_view_variant.get("can_advance", false))
	if can_advance:
		map_screen.set_note("Current node has no standalone page yet. Use Advance to move to the next story node.")
		return

	map_screen.set_note("Current node cannot be opened as a separate page.")


func _on_group_route_requested(group_view: Dictionary) -> void:
	var status_key: String = str(group_view.get("status_key", "locked"))
	if status_key == "locked":
		map_screen.set_note("This group is still locked.")
		return

	var preferred_step: Dictionary = _preferred_route_step(group_view)
	if status_key == "current" and not preferred_step.is_empty() and _step_matches_live_page(preferred_step):
		_on_open_current_node_requested()
		return

	var scene_view: Dictionary = _build_group_route_scene(group_view, preferred_step)
	scene_screen.show_scene(scene_view)
	scene_screen.set_status("Status: group route preview")
	scene_screen.set_can_advance(false)
	_show_page("scene")


func _on_advance_requested() -> void:
	if _current_page == "scene":
		scene_screen.set_status("Status: requesting advance...")
	else:
		map_screen.set_status("Status: requesting advance...")
	bridge_client.send_advance()


func _on_submit_requested(python_code: String) -> void:
	challenge_screen.set_status("Status: submitting code...")
	bridge_client.send_submit_level(python_code)


func _on_debug_toggled(debug_visible: bool) -> void:
	_set_debug_visible(debug_visible)


func _on_bridge_started() -> void:
	map_screen.set_status("Status: bridge running")
	map_screen.set_bridge_running(true)
	map_screen.set_note("Bridge started. Press Reset to fetch current state.")
	response_text.text = "Bridge started. Click Reset to fetch current state."


func _on_bridge_failed(message: String) -> void:
	map_screen.set_status("Status: bridge error")
	map_screen.set_note("Bridge error:\n%s" % message)
	scene_screen.set_status("Status: bridge error")
	challenge_screen.set_status("Status: bridge error")
	challenge_screen.show_feedback({
		"title": "Bridge Error",
		"body": message,
	})
	response_text.text = message
	_show_page("map")


func _on_response_received(response: Dictionary) -> void:
	response_text.text = JSON.stringify(response, "  ")
	_state_store.apply_response(response)

	var state: Variant = response.get("state", null)
	if state is Dictionary:
		var map_view: Dictionary = QuestMapViewModelMapperScript.map_game_state(state)
		var view_model: Dictionary = StateMapperScript.map_game_state(state)
		view_model = StateMapperScript.override_feedback(view_model, response)
		_render_map_view(map_view, state, view_model)
		_render_flow_views(view_model)
		_route_after_response(state)
		return

	_render_error_response(response)


func _render_map_view(map_view: Dictionary, state: Dictionary, view_model: Dictionary) -> void:
	map_screen.show_map(map_view)
	map_screen.set_status("Status: response ok=true")
	var action_view_variant: Variant = view_model.get("action_view", {})
	var can_advance: bool = false
	if action_view_variant is Dictionary:
		can_advance = bool(action_view_variant.get("can_advance", false))
	var can_open: bool = _has_scene_payload(state) or _has_challenge_payload(state)
	map_screen.set_can_advance(can_advance)
	map_screen.set_current_node_enterable(can_open)
	if can_open:
		map_screen.set_note("Open Current Node to enter the active story or challenge page. The map now reflects live route step state.")
	elif can_advance:
		map_screen.set_note("Current route step has no standalone page yet. Use Advance to move forward.")
	else:
		map_screen.set_note("Current route step cannot be opened as a separate page.")


func _render_flow_views(view_model: Dictionary) -> void:
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
	challenge_screen.show_feedback(view_model.get("feedback_view", {}))
	challenge_screen.set_status("Status: challenge flow ready")
	challenge_screen.set_can_submit(can_submit)


func _route_after_response(state: Dictionary) -> void:
	var mode_value: String = str(state.get("mode", ""))
	if _current_page == "map":
		return
	if mode_value == "scene" and _has_scene_payload(state):
		_show_page("scene")
		return
	if mode_value == "challenge" and _has_challenge_payload(state):
		_show_page("challenge")
		return
	_show_page("map")


func _render_error_response(response: Dictionary) -> void:
	var error_text: String = str(response.get("error", "Unknown error"))
	map_screen.set_status("Status: request failed")
	map_screen.set_note("Request failed:\n%s" % error_text)
	scene_screen.set_status("Status: request failed")
	challenge_screen.set_status("Status: request failed")
	challenge_screen.show_feedback({
		"title": "Request Failed",
		"body": error_text,
	})
	_show_page("map")


func _show_map_page() -> void:
	_show_page("map")


func _show_page(page: String) -> void:
	_current_page = page
	map_screen.visible = page == "map"
	scene_screen.visible = page == "scene"
	challenge_screen.visible = page == "challenge"


func _set_debug_visible(debug_visible: bool) -> void:
	debug_margin.visible = debug_visible
	debug_panel.visible = debug_visible
	map_screen.set_debug_visible(debug_visible)


func _has_scene_payload(state: Dictionary) -> bool:
	var scene_value: Variant = state.get("scene", null)
	if scene_value is Dictionary:
		var scene_dict: Dictionary = scene_value
		return not scene_dict.is_empty()
	return false


func _has_challenge_payload(state: Dictionary) -> bool:
	var challenge_value: Variant = state.get("challenge", null)
	if challenge_value is Dictionary:
		var challenge_dict: Dictionary = challenge_value
		return not challenge_dict.is_empty()
	return false


func _preferred_route_step(group_view: Dictionary) -> Dictionary:
	var demo_slot_variant: Variant = group_view.get("demo_slot", {})
	if demo_slot_variant is Dictionary:
		var demo_slot: Dictionary = demo_slot_variant
		var primary_step_variant: Variant = demo_slot.get("primary_step", {})
		if primary_step_variant is Dictionary and not primary_step_variant.is_empty():
			return primary_step_variant
	var practice_slot_variant: Variant = group_view.get("practice_slot", {})
	if practice_slot_variant is Dictionary:
		var practice_slot: Dictionary = practice_slot_variant
		var primary_step_variant: Variant = practice_slot.get("primary_step", {})
		if primary_step_variant is Dictionary and not primary_step_variant.is_empty():
			return primary_step_variant
	return {}


func _step_matches_live_page(step: Dictionary) -> bool:
	if _state_store == null or not _state_store.has_state():
		return false
	var state: Dictionary = _state_store.get_state()
	var target_page: String = str(step.get("target_page", "map"))
	if target_page == "scene":
		return _has_scene_payload(state)
	if target_page == "challenge":
		return _has_challenge_payload(state)
	return false


func _build_group_route_scene(group_view: Dictionary, preferred_step: Dictionary) -> Dictionary:
	var body_lines: Array[String] = []
	body_lines.append("Status: %s" % str(group_view.get("status_label", "Unknown")))
	body_lines.append(str(group_view.get("progress_label", "")))
	var current_label: String = str(group_view.get("current_label", ""))
	if current_label != "":
		body_lines.append(current_label)

	_append_slot_section(body_lines, group_view.get("demo_slot", {}))
	body_lines.append("")
	_append_slot_section(body_lines, group_view.get("practice_slot", {}))

	if not preferred_step.is_empty():
		body_lines.append("")
		body_lines.append("Selected step: %s [%s]" % [str(preferred_step.get("title", "Step")), str(preferred_step.get("status_label", "Unknown"))])
		body_lines.append("Target page: %s" % str(preferred_step.get("target_page", "map")))

	body_lines.append("")
	body_lines.append("This preview route is local to the Godot client. It does not change the bridge GameState.")

	return {
		"mode_label": "Mode: group-route",
		"node_label": "Group: %s" % str(group_view.get("group_id", "-")),
		"title": str(group_view.get("title", "Group Route")),
		"body": "\n".join(body_lines),
	}


func _append_slot_section(body_lines: Array[String], slot_variant: Variant) -> void:
	if not (slot_variant is Dictionary):
		return
	var slot: Dictionary = slot_variant
	if slot.is_empty():
		return
	body_lines.append("%s [%s | %s]:" % [str(slot.get("title", "Slot")), str(slot.get("status_label", "Unknown")), str(slot.get("progress_label", "0 / 0"))])
	var route_steps_variant: Variant = slot.get("route_steps", [])
	if route_steps_variant is Array:
		for step in route_steps_variant:
			if step is Dictionary:
				body_lines.append("- %s [%s]" % [str(step.get("title", "Step")), str(step.get("status_label", "Unknown"))])
	var practice_levels_variant: Variant = slot.get("practice_levels", [])
	if practice_levels_variant is Array and not practice_levels_variant.is_empty():
		body_lines.append("Practice Levels:")
		for level_variant in practice_levels_variant:
			if level_variant is Dictionary:
				body_lines.append("- %s [%s]" % [str(level_variant.get("title", "Level")), str(level_variant.get("status_label", "Unknown"))])
