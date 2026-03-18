extends Control
class_name GameFlowCoordinator

const DEFAULT_CHALLENGE_CODE := "print(3)\n"
const BridgeStateStoreScript = preload("res://scripts/bridge/bridge_state_store.gd")
const QuestMapSelectionPresenterScript = preload("res://scripts/map/quest_map_selection_presenter.gd")
const QuestMapMapperScript = preload("res://scripts/map/quest_map_mapper.gd")
const GameFlowFeedbackPresenterScript = preload("res://scripts/game_flow/game_flow_feedback_presenter.gd")
const GameFlowMapperScript = preload("res://scripts/game_flow/game_flow_mapper.gd")

@onready var python_bridge_client = $PythonBridgeClient
@onready var map_screen = $MapScreen
@onready var scene_screen = $SceneScreen
@onready var challenge_screen = $ChallengeScreen
@onready var debug_margin: MarginContainer = $Margin
@onready var debug_panel: PanelContainer = $Margin/DebugPanel
@onready var response_text: RichTextLabel = $Margin/DebugPanel/DebugMargin/DebugRoot/ResponseText

var _state_store: RefCounted
var _current_page: String = "map"


func _ready() -> void:
	_state_store = BridgeStateStoreScript.new()
	map_screen.start_bridge_requested.connect(_on_start_bridge_requested)
	map_screen.reset_requested.connect(_on_reset_requested)
	map_screen.advance_requested.connect(_on_advance_requested)
	map_screen.node_open_requested.connect(_on_open_current_node_requested)
	map_screen.debug_toggled.connect(_on_debug_toggled)
	map_screen.group_route_requested.connect(_on_group_route_requested)
	scene_screen.advance_requested.connect(_on_advance_requested)
	scene_screen.back_requested.connect(_show_map_page)
	challenge_screen.submit_requested.connect(_on_submit_requested)
	challenge_screen.back_requested.connect(_show_map_page)
	python_bridge_client.bridge_started.connect(_on_bridge_started)
	python_bridge_client.bridge_failed.connect(_on_bridge_failed)
	python_bridge_client.response_received.connect(_on_response_received)

	challenge_screen.initialize(DEFAULT_CHALLENGE_CODE)
	map_screen.show_map(QuestMapMapperScript.empty_map_view("Click Start Bridge, then Reset to load the current quest map."))
	map_screen.set_status("Status: idle")
	map_screen.set_note("Use Reset to load the latest quest state. Route steps now come from bridge map_route data.")
	map_screen.set_bridge_running(false)
	map_screen.set_can_advance(false)
	map_screen.set_current_node_enterable(false)
	scene_screen.show_placeholder("No scene loaded yet.")
	scene_screen.set_status("Scene flow is idle.")
	scene_screen.set_can_advance(false)
	challenge_screen.show_challenge({})
	challenge_screen.show_feedback(GameFlowFeedbackPresenterScript.empty_feedback_view("Feedback will appear here."))
	challenge_screen.set_status("Challenge flow is idle.")
	challenge_screen.set_can_submit(false)
	_set_debug_visible(false)
	_show_page("map")


func _on_start_bridge_requested() -> void:
	map_screen.set_status("Status: starting bridge...")
	python_bridge_client.start_bridge()


func _on_reset_requested() -> void:
	map_screen.set_status("Status: requesting reset...")
	python_bridge_client.send_reset()


func _on_open_current_node_requested() -> void:
	if not _state_store.has_state():
		map_screen.set_note("No GameState loaded yet. Start the bridge and press Reset first.")
		return

	var state: Dictionary = _state_store.get_state()
	var target_page: String = _resolved_page_for_state(state)
	if target_page != "map":
		_show_page(target_page)
		return

	if _state_can_advance(state):
		map_screen.set_note("Current node has no standalone page yet. Use Advance to move to the next story node.")
		return

	map_screen.set_note("Current node cannot be opened as a separate page.")


func _on_group_route_requested(group_view: Dictionary) -> void:
	var status_key: String = str(group_view.get("status_key", "locked"))
	if status_key == "locked":
		map_screen.set_note("This group is still locked.")
		return

	var preferred_step: Dictionary = QuestMapSelectionPresenterScript.preferred_route_step(group_view)
	if status_key == "current" and not preferred_step.is_empty() and _step_matches_live_page(preferred_step):
		_on_open_current_node_requested()
		return

	_show_group_route_preview(group_view, preferred_step)


func _on_advance_requested() -> void:
	if _current_page == "scene":
		scene_screen.set_status("Status: requesting advance...")
	else:
		map_screen.set_status("Status: requesting advance...")
	python_bridge_client.send_advance()


func _on_submit_requested(python_code: String) -> void:
	challenge_screen.set_status("Status: submitting code...")
	python_bridge_client.send_submit_level(python_code)


func _on_debug_toggled(debug_visible: bool) -> void:
	_set_debug_visible(debug_visible)


func _on_bridge_started() -> void:
	map_screen.set_status("Status: bridge running")
	map_screen.set_bridge_running(true)
	map_screen.set_note("Bridge started. Press Reset to fetch current state.")
	response_text.text = "Bridge started. Click Reset to fetch current state."


func _on_bridge_failed(message: String) -> void:
	response_text.text = message
	_apply_error_ui(
		"Status: bridge error",
		"Bridge error:\n%s" % message,
		"Bridge Error",
		message
	)

func _on_response_received(response: Dictionary) -> void:
	response_text.text = JSON.stringify(response, "  ")
	_state_store.apply_response(response)

	var state: Variant = response.get("state", null)
	if state is Dictionary:
		_apply_success_state(state, response)
		return

	_apply_error_response(response)


func _render_map_view(map_view: Dictionary, state: Dictionary, view_model: Dictionary) -> void:
	map_screen.show_map(map_view)
	map_screen.set_status("Status: response ok=true")
	var can_advance: bool = _can_advance_from_view_model(view_model)
	var can_open: bool = _current_state_has_openable_page(state)
	map_screen.set_can_advance(can_advance)
	map_screen.set_current_node_enterable(can_open)
	map_screen.set_note(_map_note_for_state(state, can_advance, can_open))


func _apply_success_state(state: Dictionary, response: Dictionary) -> void:
	var map_view: Dictionary = QuestMapMapperScript.map_game_state(state)
	var view_model: Dictionary = GameFlowMapperScript.map_game_state(state)
	var feedback_view: Dictionary = GameFlowFeedbackPresenterScript.build_feedback_view(view_model, response)
	_render_map_view(map_view, state, view_model)
	_render_flow_views(view_model, feedback_view)
	_route_after_response(state)


func _state_can_advance(state: Dictionary) -> bool:
	return _can_advance_from_view_model(GameFlowMapperScript.map_game_state(state))


func _show_group_route_preview(group_view: Dictionary, preferred_step: Dictionary) -> void:
	var scene_view: Dictionary = QuestMapSelectionPresenterScript.build_group_route_scene_view(group_view, preferred_step)
	scene_screen.show_scene(scene_view)
	scene_screen.set_status("Status: group route preview")
	scene_screen.set_can_advance(false)
	_show_page("scene")


func _can_advance_from_view_model(view_model: Dictionary) -> bool:
	var action_view_variant: Variant = view_model.get("action_view", {})
	if action_view_variant is Dictionary:
		return bool(action_view_variant.get("can_advance", false))
	return false


func _current_state_has_openable_page(state: Dictionary) -> bool:
	return _has_scene_payload(state) or _has_challenge_payload(state)


func _map_note_for_state(state: Dictionary, can_advance: bool, can_open: bool) -> String:
	if can_open:
		return "Open Current Node to enter the active story or challenge page. The map now reflects live route step state."
	if can_advance:
		return "Current route step has no standalone page yet. Use Advance to move forward."
	return "Current route step cannot be opened as a separate page."


func _render_flow_views(view_model: Dictionary, feedback_view: Dictionary) -> void:
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
	challenge_screen.set_status("Status: challenge flow ready")
	challenge_screen.set_can_submit(can_submit)


func _route_after_response(state: Dictionary) -> void:
	if _current_page == "map":
		return
	_show_page(_resolved_page_for_state(state))


func _resolved_page_for_state(state: Dictionary) -> String:
	var mode_value: String = str(state.get("mode", ""))
	if mode_value == "scene" and _has_scene_payload(state):
		return "scene"
	if mode_value == "challenge" and _has_challenge_payload(state):
		return "challenge"
	return "map"


func _apply_error_response(response: Dictionary) -> void:
	var error_text: String = str(response.get("error", "Unknown error"))
	_apply_error_ui(
		"Status: request failed",
		"Request failed:\n%s" % error_text,
		"Request Failed",
		error_text
	)

func _apply_error_ui(map_status: String, map_note: String, feedback_title: String, feedback_body: String) -> void:
	map_screen.set_status(map_status)
	map_screen.set_note(map_note)
	scene_screen.set_status(map_status)
	challenge_screen.set_status(map_status)
	challenge_screen.show_feedback({
		"title": feedback_title,
		"body": feedback_body,
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
