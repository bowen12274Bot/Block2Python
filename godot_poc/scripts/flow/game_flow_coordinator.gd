extends Control
class_name GameFlowCoordinator

const DEFAULT_CHALLENGE_CODE := "print(3)\n"
const BridgeStateStoreScript = preload("res://scripts/bridge/bridge_state_store.gd")
const QuestMapMapperScript = preload("res://scripts/map/quest_map_mapper.gd")
const GameFlowFeedbackPresenterScript = preload("res://scripts/game_flow/game_flow_feedback_presenter.gd")
const GameFlowMapperScript = preload("res://scripts/game_flow/game_flow_mapper.gd")
const GameFlowPageRouterScript = preload("res://scripts/flow/game_flow_page_router.gd")
const GameFlowScreenPresenterScript = preload("res://scripts/flow/game_flow_screen_presenter.gd")

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
	map_screen.stage_demo_requested.connect(_on_stage_demo_requested)
	map_screen.stage_practice_requested.connect(_on_stage_practice_requested)
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
	map_screen.set_note("Use Reset to load the latest quest state. Group and slot state now come directly from bridge map_route data.")
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
	var target_page: String = GameFlowPageRouterScript.resolved_page_for_state(state)
	if target_page != "map":
		_show_page(target_page)
		return

	if _state_can_advance(state):
		map_screen.set_note("Current node has no standalone page yet. Use Advance to move to the next story node.")
		return

	map_screen.set_note("Current node cannot be opened as a separate page.")


func _on_stage_demo_requested(group_id: String) -> void:
	if not _state_store.has_state():
		map_screen.set_note("No GameState loaded yet. Start the bridge and press Reset first.")
		return
	map_screen.set_status("Status: opening demo...")
	python_bridge_client.send_start_group_demo(group_id)


func _on_stage_practice_requested(group_id: String) -> void:
	if not _state_store.has_state():
		map_screen.set_note("No GameState loaded yet. Start the bridge and press Reset first.")
		return
	map_screen.set_status("Status: opening practice...")
	python_bridge_client.send_start_group_practice(group_id)


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


func _apply_success_state(state: Dictionary, response: Dictionary) -> void:
	var map_view: Dictionary = QuestMapMapperScript.map_game_state(state)
	var view_model: Dictionary = GameFlowMapperScript.map_game_state(state)
	var feedback_view: Dictionary = GameFlowFeedbackPresenterScript.build_feedback_view(view_model, response)
	var can_open: bool = GameFlowPageRouterScript.current_state_has_openable_page(state)
	GameFlowScreenPresenterScript.render_map_view(map_screen, map_view, state, view_model, can_open)
	GameFlowScreenPresenterScript.render_flow_views(scene_screen, challenge_screen, view_model, feedback_view)
	_route_after_response(state)


func _state_can_advance(state: Dictionary) -> bool:
	return GameFlowScreenPresenterScript.can_advance_from_view_model(GameFlowMapperScript.map_game_state(state))


func _route_after_response(state: Dictionary) -> void:
	_show_page(GameFlowPageRouterScript.resolved_page_for_state(state))


func _apply_error_response(response: Dictionary) -> void:
	var error_text: String = str(response.get("error", "Unknown error"))
	_apply_error_ui(
		"Status: request failed",
		"Request failed:\n%s" % error_text,
		"Request Failed",
		error_text
	)


func _apply_error_ui(map_status: String, map_note: String, feedback_title: String, feedback_body: String) -> void:
	GameFlowScreenPresenterScript.apply_error_ui(map_screen, scene_screen, challenge_screen, map_status, map_note, feedback_title, feedback_body)
	_show_page("map")


func _show_map_page() -> void:
	_show_page("map")


func _show_page(page: String) -> void:
	_current_page = page
	GameFlowPageRouterScript.show_page(page, map_screen, scene_screen, challenge_screen)


func _set_debug_visible(debug_visible: bool) -> void:
	debug_margin.visible = debug_visible
	debug_panel.visible = debug_visible
	map_screen.set_debug_visible(debug_visible)
