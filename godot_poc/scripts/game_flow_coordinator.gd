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

@onready var start_bridge_button: Button = $MapScreen/Margin/Root/Buttons/StartBridgeButton
@onready var reset_button: Button = $MapScreen/Margin/Root/Buttons/ResetButton
@onready var map_advance_button: Button = $MapScreen/Margin/Root/Buttons/AdvanceButton
@onready var open_node_button: Button = $MapScreen/Margin/Root/Buttons/OpenNodeButton
@onready var debug_toggle_button: Button = $MapScreen/Margin/Root/Buttons/DebugToggleButton

var _state_store: RefCounted
var _current_page: String = "map"


func _ready() -> void:
	_state_store = BridgeStateStoreScript.new()
	start_bridge_button.pressed.connect(_on_start_bridge_requested)
	reset_button.pressed.connect(_on_reset_requested)
	map_advance_button.pressed.connect(_on_advance_requested)
	open_node_button.pressed.connect(_on_open_current_node_requested)
	debug_toggle_button.toggled.connect(_on_debug_toggled)
	bridge_client.bridge_started.connect(_on_bridge_started)
	bridge_client.bridge_failed.connect(_on_bridge_failed)
	bridge_client.response_received.connect(_on_response_received)

	challenge_screen.initialize(DEFAULT_CHALLENGE_CODE)
	map_screen.show_map(QuestMapViewModelMapperScript.empty_map_view("Click Start Bridge, then Reset to load the current quest map."))
	map_screen.set_status("Status: idle")
	map_screen.set_note("Use Reset to load the latest quest state. Then open the current node to enter story or challenge flow.")
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


func _on_advance_requested() -> void:
	if _current_page == "scene":
		scene_screen.set_status("Status: requesting advance...")
	else:
		map_screen.set_status("Status: requesting advance...")
	bridge_client.send_advance()


func _on_submit_requested(python_code: String) -> void:
	challenge_screen.set_status("Status: submitting code...")
	bridge_client.send_submit_level(python_code)


@warning_ignore("shadowed_variable_base_class")
func _on_debug_toggled(is_visible: bool) -> void:
	_set_debug_visible(is_visible)


func _on_bridge_started() -> void:
	map_screen.set_status("Status: bridge running")
	map_screen.set_bridge_running(true)
	map_screen.set_note("Bridge started. Press Reset to fetch the current quest state.")
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
		map_screen.set_note("Open Current Node to enter the active story or challenge page. The map reflects the live quest state.")
	elif can_advance:
		map_screen.set_note("This node has no standalone page. Use Advance to move to the next story node.")
	else:
		map_screen.set_note("Current node cannot be opened as a separate page.")


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


func _set_debug_visible(is_visible: bool) -> void:
	debug_margin.visible = is_visible
	debug_panel.visible = is_visible
	map_screen.set_debug_visible(is_visible)


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
