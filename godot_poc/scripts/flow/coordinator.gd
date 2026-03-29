extends Control
class_name FlowCoordinator

const DEFAULT_PRACTICE_CODE := "print(3)\n"
const BridgeStateStoreScript = preload("res://scripts/bridge/bridge_state_store.gd")
const QuestMapMapperScript = preload("res://scripts/map/mappers/quest_map_mapper.gd")
const GameFlowFeedbackPresenterScript = preload("res://scripts/game_flow/presentation/feedback_presenter.gd")
const GameFlowMapperScript = preload("res://scripts/game_flow/mappers/mapper.gd")
const FlowPageRouterScript = preload("res://scripts/flow/page_router.gd")
const FlowScreenPresenterScript = preload("res://scripts/flow/screen_presenter.gd")
const FlowToolboxControllerScript = preload("res://scripts/flow/toolbox/toolbox_controller.gd")

@onready var python_bridge_client = $PythonBridgeClient
@onready var entry_screen = $EntryScreen
@onready var map_screen = $MapScreen
@onready var scene_screen = $SceneScreen
@onready var demo_screen = $DemoScreen
@onready var practice_screen = $PracticeScreen
@onready var debug_margin: MarginContainer = $Margin
@onready var debug_panel: PanelContainer = $Margin/DebugPanel
@onready var response_text: RichTextLabel = $Margin/DebugPanel/DebugMargin/DebugRoot/ResponseText

var _state_store: RefCounted
var _current_page: String = "entry"
var _toolbox_controller: RefCounted


func _ready() -> void:
	_state_store = BridgeStateStoreScript.new()
	_toolbox_controller = FlowToolboxControllerScript.new()
	_toolbox_controller.setup(self, demo_screen, practice_screen)

	entry_screen.start_bridge_requested.connect(_on_start_bridge_requested)
	entry_screen.reset_requested.connect(_on_reset_requested)
	entry_screen.create_profile_requested.connect(_on_create_profile_requested)
	map_screen.start_bridge_requested.connect(_on_start_bridge_requested)
	map_screen.reset_requested.connect(_on_reset_requested)
	map_screen.advance_requested.connect(_on_advance_requested)
	map_screen.node_open_requested.connect(_on_open_current_node_requested)
	map_screen.debug_toggled.connect(_on_debug_toggled)
	map_screen.stage_story_requested.connect(_on_stage_story_requested)
	map_screen.stage_demo_requested.connect(_on_stage_demo_requested)
	map_screen.stage_practice_requested.connect(_on_stage_practice_requested)
	scene_screen.advance_requested.connect(_on_advance_requested)
	scene_screen.back_requested.connect(_show_map_page)
	demo_screen.advance_requested.connect(_on_demo_advance_requested)
	demo_screen.convert_requested.connect(_on_demo_convert_requested)
	demo_screen.back_requested.connect(_show_map_page)
	practice_screen.run_requested.connect(_on_run_requested)
	practice_screen.submit_requested.connect(_on_submit_requested)
	practice_screen.next_requested.connect(_on_next_requested)
	practice_screen.open_toolbox_requested.connect(_on_open_toolbox_requested)
	practice_screen.toolbox_confirmation_accepted.connect(_on_toolbox_confirmation_accepted)
	practice_screen.back_requested.connect(_show_map_page)
	python_bridge_client.bridge_started.connect(_on_bridge_started)
	python_bridge_client.bridge_failed.connect(_on_bridge_failed)
	python_bridge_client.response_received.connect(_on_response_received)

	entry_screen.show_profile({})
	entry_screen.set_status("Status: start bridge, then create your profile.")
	entry_screen.set_bridge_running(false)
	practice_screen.initialize(DEFAULT_PRACTICE_CODE)
	map_screen.show_map(QuestMapMapperScript.empty_map_view("Click Start Bridge, then Reset to load the current quest map."))
	map_screen.set_status("Status: idle")
	map_screen.set_note("Use Reset to load the latest quest state. Group and slot state now come directly from bridge map_route data.")
	map_screen.set_bridge_running(false)
	map_screen.set_can_advance(false)
	map_screen.set_current_node_enterable(false)
	scene_screen.show_placeholder("No scene loaded yet.")
	scene_screen.set_status("Scene flow is idle.")
	scene_screen.set_can_advance(false)
	scene_screen.set_can_go_back(false)
	demo_screen.show_placeholder("Demo placeholder will appear here.")
	demo_screen.set_status("Demo flow is idle.")
	demo_screen.set_can_convert(false)
	demo_screen.set_can_advance(false)
	demo_screen.set_can_go_back(true)
	practice_screen.show_practice({})
	practice_screen.show_feedback(GameFlowFeedbackPresenterScript.empty_feedback_view("Feedback will appear here."))
	practice_screen.set_status("Practice flow is idle.")
	practice_screen.set_can_run(false)
	practice_screen.set_can_submit(false)
	practice_screen.set_can_next(false)
	_set_debug_visible(false)
	_show_page("entry")
	set_process(true)


func _process(_delta: float) -> void:
	_toolbox_controller.process_tick()


func _on_start_bridge_requested() -> void:
	entry_screen.set_status("Status: starting bridge...")
	map_screen.set_status("Status: starting bridge...")
	python_bridge_client.start_bridge()


func _on_reset_requested() -> void:
	entry_screen.set_status("Status: requesting reset...")
	map_screen.set_status("Status: requesting reset...")
	python_bridge_client.send_reset()


func _on_create_profile_requested(player_name: String, gender: String) -> void:
	entry_screen.set_status("Status: creating profile...")
	python_bridge_client.send_create_player_profile(player_name, gender)


func _on_open_current_node_requested() -> void:
	if not _state_store.has_state():
		map_screen.set_note("No GameState loaded yet. Start the bridge and press Reset first.")
		return

	var state: Dictionary = _state_store.get_state()
	var target_page: String = FlowPageRouterScript.resolved_page_for_state(state)
	if target_page != "map":
		_show_page(target_page)
		return

	if _state_can_advance(state):
		map_screen.set_note("Current node has no standalone page yet. Use Advance to move to the next story node.")
		return

	map_screen.set_note("Current node cannot be opened as a separate page.")


func _on_stage_story_requested(group_id: String) -> void:
	if not _state_store.has_state():
		map_screen.set_note("No GameState loaded yet. Start the bridge and press Reset first.")
		return
	map_screen.set_status("Status: opening story...")
	python_bridge_client.send_start_group_story(group_id)


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
	if _current_page == "scene" and _state_store.has_state() and not bool(_state_store.get_state().get("intro_completed", false)):
		scene_screen.set_status("Status: completing opening intro...")
		python_bridge_client.send_complete_intro()
		return
	if _current_page == "scene":
		scene_screen.set_status("Status: requesting advance...")
	else:
		map_screen.set_status("Status: requesting advance...")
	python_bridge_client.send_advance()


func _on_run_requested(python_code: String) -> void:
	if _toolbox_controller.is_challenge_workspace_active():
		practice_screen.set_status("Status: running toolkit...")
		python_bridge_client.send_verify_toolbox_level(_toolbox_controller.workspace_python_code(), _toolbox_controller.workspace_block_json())
		return
	practice_screen.set_status("Status: running code...")
	python_bridge_client.send_run_level(python_code)


func _on_submit_requested(python_code: String) -> void:
	practice_screen.set_status("Status: submitting code...")
	python_bridge_client.send_submit_level(python_code)


func _on_next_requested() -> void:
	practice_screen.set_status("Status: moving to next level...")
	python_bridge_client.send_next_level()


func _on_demo_advance_requested() -> void:
	demo_screen.set_status("Status: continuing demo flow...")
	python_bridge_client.send_advance()


func _on_demo_convert_requested() -> void:
	_toolbox_controller.request_demo_convert()
	var demo_view: Dictionary = _current_demo_view()
	_toolbox_controller.ensure_demo_helper(demo_view)


func _on_open_toolbox_requested() -> void:
	var practice_view: Dictionary = _current_practice_view()
	if bool(practice_view.get("toolbox_opened", false)):
		_toolbox_controller.toggle_challenge_helper(practice_view, _current_page)
		return
	var penalty_percent: Variant = practice_view.get("toolbox_penalty_percent", null)
	if penalty_percent == null:
		_toolbox_controller.toggle_challenge_helper(practice_view, _current_page)
		return
	practice_screen.prompt_toolbox_confirmation(int(penalty_percent))


func _on_toolbox_confirmation_accepted() -> void:
	python_bridge_client.send_confirm_toolbox_open()
	var practice_view: Dictionary = _current_practice_view()
	if bool(practice_view.get("toolbox_opened", false)):
		_toolbox_controller.toggle_challenge_helper(practice_view, _current_page)


func _on_debug_toggled(debug_visible: bool) -> void:
	_set_debug_visible(debug_visible)


func _on_bridge_started() -> void:
	entry_screen.set_status("Status: bridge running")
	entry_screen.set_bridge_running(true)
	map_screen.set_status("Status: bridge running")
	map_screen.set_bridge_running(true)
	map_screen.set_note("Bridge started. Press Reset to fetch current state.")
	response_text.text = "Bridge started. Click Reset to fetch current state."
	_toolbox_controller.prewarm_helper()


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
	var can_open: bool = FlowPageRouterScript.current_state_has_openable_page(state)
	entry_screen.show_profile(view_model.get("player_profile_view", {}))
	entry_screen.set_status(_entry_status_text(view_model.get("player_profile_view", {})))
	entry_screen.set_bridge_running(python_bridge_client.is_running())
	FlowScreenPresenterScript.render_map_view(map_screen, map_view, state, view_model, can_open)
	FlowScreenPresenterScript.render_flow_views(scene_screen, demo_screen, practice_screen, view_model, feedback_view)
	scene_screen.set_can_go_back(bool(state.get("intro_completed", false)))
	_toolbox_controller.apply_lock_state()
	_append_debug_state(view_model)
	_route_after_response(state)


func _append_debug_state(view_model: Dictionary) -> void:
	var practice_view: Dictionary = view_model.get("practice_view", {})
	var action_view: Dictionary = view_model.get("action_view", {})
	var focus_owner: Control = get_viewport().gui_get_focus_owner()
	var focus_name: String = "<none>"
	if focus_owner != null:
		focus_name = "%s (%s)" % [focus_owner.name, focus_owner.get_class()]

	var debug_lines: Array[String] = [
		"",
		"--- UI Debug ---",
		"current_page=%s" % _current_page,
		"practice_view.code_editable=%s" % str(practice_view.get("code_editable", false)),
		"action_view.can_submit=%s" % str(action_view.get("can_submit", false)),
		"action_view.can_next=%s" % str(action_view.get("can_next", false)),
		"focus_owner=%s" % focus_name,
	]
	debug_lines.append_array(_toolbox_controller.debug_state_lines())
	response_text.text += "\n" + "\n".join(debug_lines)


func _state_can_advance(state: Dictionary) -> bool:
	return FlowScreenPresenterScript.can_advance_from_view_model(GameFlowMapperScript.map_game_state(state))


func _route_after_response(state: Dictionary) -> void:
	_show_page(FlowPageRouterScript.resolved_page_for_state(state))


func _apply_error_response(response: Dictionary) -> void:
	var error_text: String = str(response.get("error", "Unknown error"))
	_apply_error_ui(
		"Status: request failed",
		"Request failed:\n%s" % error_text,
		"Request Failed",
		error_text
	)


func _apply_error_ui(map_status: String, map_note: String, feedback_title: String, feedback_body: String) -> void:
	entry_screen.set_status(map_status)
	FlowScreenPresenterScript.apply_error_ui(map_screen, scene_screen, demo_screen, practice_screen, map_status, map_note, feedback_title, feedback_body)
	_toolbox_controller.apply_lock_state()
	_show_page("entry")


func _show_map_page() -> void:
	_show_page("map")


func _show_page(page: String) -> void:
	_current_page = page
	FlowPageRouterScript.show_page(page, entry_screen, map_screen, scene_screen, demo_screen, practice_screen)
	var demo_view: Dictionary = _current_demo_view()
	_toolbox_controller.handle_page_changed(page, demo_view)


func _current_view_model() -> Dictionary:
	if not _state_store.has_state():
		return {}
	return GameFlowMapperScript.map_game_state(_state_store.get_state())


func _current_demo_view() -> Dictionary:
	return _current_view_model().get("demo_view", {})


func _current_practice_view() -> Dictionary:
	return _current_view_model().get("practice_view", {})

func _set_debug_visible(debug_visible: bool) -> void:
	debug_margin.visible = debug_visible
	debug_panel.visible = debug_visible
	map_screen.set_debug_visible(debug_visible)


func _entry_status_text(profile_view: Dictionary) -> String:
	if bool(profile_view.get("profile_created", false)):
		return "Status: profile ready, opening briefing unlocked"
	return "Status: create your profile to enter the opening briefing"


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_toolbox_controller.stop_helper(true, _current_page)

