extends Control
class_name EntryScreen

signal start_bridge_requested()
signal reset_requested()
signal create_profile_requested(name: String, gender: String)

@onready var status_label: Label = $ContentLayer/ContentCenter/ContentStack/StatusLayer/StatusMargin/StatusStack/StatusLabel
@onready var summary_label: Label = $ContentLayer/ContentCenter/ContentStack/StatusLayer/StatusMargin/StatusStack/SummaryLabel
@onready var start_bridge_button: Button = $OverlayLayer/DeveloperLayer/DeveloperPanel/DeveloperMargin/DeveloperStack/BridgeButtons/StartBridgeButton
@onready var reset_button: Button = $OverlayLayer/DeveloperLayer/DeveloperPanel/DeveloperMargin/DeveloperStack/BridgeButtons/ResetButton
@onready var name_input: LineEdit = $ContentLayer/ContentCenter/ContentStack/NameInputLayer/NameInput
@onready var male_card: PanelContainer = $ContentLayer/ContentCenter/ContentStack/CharacterSelectLayer/CharacterRow/MaleCard
@onready var female_card: PanelContainer = $ContentLayer/ContentCenter/ContentStack/CharacterSelectLayer/CharacterRow/FemaleCard
@onready var male_glow: ColorRect = $ContentLayer/ContentCenter/ContentStack/CharacterSelectLayer/CharacterRow/MaleCard/MaleCardMargin/MaleCardRoot/MaleSelectionGlow
@onready var female_glow: ColorRect = $ContentLayer/ContentCenter/ContentStack/CharacterSelectLayer/CharacterRow/FemaleCard/FemaleCardMargin/FemaleCardRoot/FemaleSelectionGlow
@onready var male_button: CheckBox = $ContentLayer/ContentCenter/ContentStack/CharacterSelectLayer/CharacterRow/MaleCard/MaleCardMargin/MaleCardRoot/MaleButton
@onready var female_button: CheckBox = $ContentLayer/ContentCenter/ContentStack/CharacterSelectLayer/CharacterRow/FemaleCard/FemaleCardMargin/FemaleCardRoot/FemaleButton
@onready var create_button: Button = $ContentLayer/ContentCenter/ContentStack/ActionLayer/CreateButton

var _bridge_running: bool = false


func _ready() -> void:
	start_bridge_button.pressed.connect(func() -> void:
		start_bridge_requested.emit()
	)
	reset_button.pressed.connect(func() -> void:
		reset_requested.emit()
	)
	create_button.pressed.connect(_on_create_button_pressed)
	name_input.text_changed.connect(func(_new_text: String) -> void:
		_refresh_form_state()
	)
	name_input.text_submitted.connect(func(_new_text: String) -> void:
		if _can_submit_profile():
			_on_create_button_pressed()
	)
	male_button.toggled.connect(func(_pressed: bool) -> void:
		_refresh_selection_state()
	)
	female_button.toggled.connect(func(_pressed: bool) -> void:
		_refresh_selection_state()
	)
	male_card.gui_input.connect(func(event: InputEvent) -> void:
		_on_card_gui_input(event, "male")
	)
	female_card.gui_input.connect(func(event: InputEvent) -> void:
		_on_card_gui_input(event, "female")
	)
	name_input.focus_mode = Control.FOCUS_ALL
	_refresh_selection_state()
	call_deferred("_refresh_form_state")


func show_profile(profile_view: Dictionary) -> void:
	var profile_name: String = str(profile_view.get("name", ""))
	var profile_created: bool = bool(profile_view.get("profile_created", false))
	var is_editing_name: bool = name_input.has_focus()
	if profile_created or not is_editing_name:
		name_input.text = profile_name
	var gender: String = str(profile_view.get("gender", ""))
	male_button.button_pressed = gender == "male"
	female_button.button_pressed = gender == "female"
	_refresh_selection_state()
	if profile_created:
		var display_name: String = str(profile_view.get("display_name", profile_view.get("name", "Player")))
		var gender_label: String = str(profile_view.get("gender_label", gender))
		summary_label.text = "Profile ready: %s (%s)" % [display_name, gender_label]
	else:
		summary_label.text = _entry_hint_text()
	_refresh_form_state()


func set_status(text: String) -> void:
	status_label.text = text


func set_bridge_running(is_running: bool) -> void:
	_bridge_running = is_running
	start_bridge_button.disabled = is_running
	reset_button.disabled = not is_running
	_refresh_form_state()


func focus_name_input() -> void:
	if name_input == null or not _is_name_input_available():
		return
	name_input.call_deferred("grab_focus")
	name_input.call_deferred("select_all")


func _on_create_button_pressed() -> void:
	if _selected_gender() == "":
		set_status("Status: choose a character first.")
		return
	var trimmed_name: String = name_input.text.strip_edges()
	if trimmed_name == "":
		set_status("Status: enter a player name.")
		focus_name_input()
		return
	set_status("Status: creating profile...")
	create_profile_requested.emit(trimmed_name, _selected_gender())


func _selected_gender() -> String:
	if male_button.button_pressed:
		return "male"
	if female_button.button_pressed:
		return "female"
	return ""


func _refresh_selection_state() -> void:
	male_glow.visible = male_button.button_pressed
	female_glow.visible = female_button.button_pressed
	male_card.self_modulate = Color(0.98, 0.98, 1.0, 1.0) if male_button.button_pressed else Color(0.82, 0.84, 0.92, 1.0)
	female_card.self_modulate = Color(1.0, 0.97, 0.99, 1.0) if female_button.button_pressed else Color(0.82, 0.84, 0.92, 1.0)
	_refresh_form_state()


func _on_card_gui_input(event: InputEvent, gender: String) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_select_gender(gender)


func _select_gender(gender: String) -> void:
	male_button.button_pressed = gender == "male"
	female_button.button_pressed = gender == "female"
	_refresh_selection_state()
	if _is_name_input_available():
		focus_name_input()


func _refresh_form_state() -> void:
	var name_available: bool = _is_name_input_available()
	name_input.editable = name_available
	name_input.placeholder_text = "Enter your player name" if name_available else "Choose your avatar first"
	create_button.disabled = false
	if not bool(summary_label.text.begins_with("Profile ready:")):
		summary_label.text = _entry_hint_text()


func _is_name_input_available() -> bool:
	return _selected_gender() != ""


func _can_submit_profile() -> bool:
	return _selected_gender() != "" and name_input.text.strip_edges() != ""


func _entry_hint_text() -> String:
	if _selected_gender() == "":
		return "Step 1: choose your avatar."
	if name_input.text.strip_edges() == "":
		return "Step 2: enter your player name."
	return "Step 3: create your character."
