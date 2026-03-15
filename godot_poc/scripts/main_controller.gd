extends Control
class_name MainController

const DEFAULT_CHALLENGE_CODE := "print(3)\n"
const BridgeStateStoreScript = preload("res://scripts/bridge_state_store.gd")
const StateMapperScript = preload("res://scripts/state_mapper.gd")

@onready var bridge_client: Node = $BridgeClient
@onready var start_bridge_button: Button = $Margin/Scroll/Root/Buttons/StartBridgeButton
@onready var advance_button: Button = $Margin/Scroll/Root/Buttons/AdvanceButton
@onready var submit_button: Button = $Margin/Scroll/Root/Buttons/SubmitButton
@onready var reset_button: Button = $Margin/Scroll/Root/Buttons/ResetButton
@onready var debug_toggle_button: Button = $Margin/Scroll/Root/Buttons/DebugToggleButton
@onready var status_label: Label = $Margin/Scroll/Root/StatusLabel
@onready var scene_panel = $Margin/Scroll/Root/ClientColumn/ScenePanel
@onready var challenge_panel = $Margin/Scroll/Root/ClientColumn/CodePanel
@onready var feedback_panel = $Margin/Scroll/Root/ClientColumn/FeedbackPanel
@onready var debug_panel: PanelContainer = $Margin/Scroll/Root/DebugPanel
@onready var response_text: RichTextLabel = $Margin/Scroll/Root/DebugPanel/DebugMargin/DebugRoot/ResponseText

var _state_store: RefCounted


func _ready() -> void:
    _state_store = BridgeStateStoreScript.new()
    start_bridge_button.pressed.connect(_on_start_bridge_pressed)
    advance_button.pressed.connect(_on_advance_pressed)
    submit_button.pressed.connect(_on_submit_pressed)
    reset_button.pressed.connect(_on_reset_pressed)
    debug_toggle_button.toggled.connect(_on_debug_toggled)
    bridge_client.bridge_started.connect(_on_bridge_started)
    bridge_client.bridge_failed.connect(_on_bridge_failed)
    bridge_client.response_received.connect(_on_response_received)
    advance_button.disabled = true
    submit_button.disabled = true
    reset_button.disabled = true
    challenge_panel.initialize(DEFAULT_CHALLENGE_CODE)
    scene_panel.show_placeholder("No scene loaded yet.")
    feedback_panel.show_feedback(StateMapperScript.empty_feedback_view("Feedback will appear here."))
    _set_debug_visible(false)


func _on_start_bridge_pressed() -> void:
    status_label.text = "Status: starting bridge..."
    bridge_client.start_bridge()


func _on_advance_pressed() -> void:
    status_label.text = "Status: requesting advance..."
    bridge_client.send_advance()


func _on_submit_pressed() -> void:
    status_label.text = "Status: submitting code..."
    bridge_client.send_submit_level(challenge_panel.get_python_code())


func _on_reset_pressed() -> void:
    status_label.text = "Status: requesting reset..."
    bridge_client.send_reset()


func _on_debug_toggled(button_pressed: bool) -> void:
    _set_debug_visible(button_pressed)


func _on_bridge_started() -> void:
    status_label.text = "Status: bridge running"
    reset_button.disabled = false
    start_bridge_button.disabled = true
    feedback_panel.show_feedback(StateMapperScript.empty_feedback_view("Bridge started. Click Reset to fetch the initial GameState."))
    response_text.text = "Bridge started. Click Reset to fetch initial state."


func _on_bridge_failed(message: String) -> void:
    status_label.text = "Status: bridge error"
    response_text.text = message
    feedback_panel.show_feedback({
        "title": "Bridge Error",
        "body": message,
    })


func _on_response_received(response: Dictionary) -> void:
    response_text.text = JSON.stringify(response, "  ")
    status_label.text = "Status: response ok=%s" % str(bool(response.get("ok", false)))
    _state_store.apply_response(response)

    var state: Variant = response.get("state", null)
    if state is Dictionary:
        var view_model: Dictionary = StateMapperScript.map_game_state(state)
        view_model = StateMapperScript.override_feedback(view_model, response)
        _render_view_model(view_model)
        return

    _render_error_response(response)


func _render_view_model(view_model: Dictionary) -> void:
    var action_view: Variant = view_model.get("action_view", {})
    var can_advance: bool = false
    var can_submit: bool = false
    if action_view is Dictionary:
        can_advance = bool(action_view.get("can_advance", false))
        can_submit = bool(action_view.get("can_submit", false))

    advance_button.disabled = not can_advance
    submit_button.disabled = not can_submit
    scene_panel.show_scene(view_model.get("scene_view", {}))
    challenge_panel.show_challenge(view_model.get("challenge_view", {}))
    feedback_panel.show_feedback(view_model.get("feedback_view", {}))


func _render_error_response(response: Dictionary) -> void:
    advance_button.disabled = true
    submit_button.disabled = true

    if _state_store.has_state():
        var stored_view_model: Dictionary = StateMapperScript.map_game_state(_state_store.get_state())
        stored_view_model = StateMapperScript.override_feedback(stored_view_model, response)
        _render_view_model(stored_view_model)
        return

    scene_panel.show_placeholder("No state in response.")
    challenge_panel.show_challenge({})
    feedback_panel.show_feedback({
        "title": "Request Failed",
        "body": str(response.get("error", "Unknown error")),
    })


func _set_debug_visible(is_visible: bool) -> void:
    debug_panel.visible = is_visible
    debug_toggle_button.text = "Hide Debug" if is_visible else "Show Debug"
