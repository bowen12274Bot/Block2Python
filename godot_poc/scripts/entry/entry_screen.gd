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


func _ready() -> void:
	start_bridge_button.pressed.connect(func() -> void:
		start_bridge_requested.emit()
	)
	reset_button.pressed.connect(func() -> void:
		reset_requested.emit()
	)
	create_button.pressed.connect(_on_create_button_pressed)
	male_button.toggled.connect(func(_pressed: bool) -> void:
		_refresh_selection_state()
	)
	female_button.toggled.connect(func(_pressed: bool) -> void:
		_refresh_selection_state()
	)
	_refresh_selection_state()


func show_profile(profile_view: Dictionary) -> void:
	name_input.text = str(profile_view.get("name", ""))
	var gender: String = str(profile_view.get("gender", ""))
	male_button.button_pressed = gender == "male"
	female_button.button_pressed = gender == "female"
	_refresh_selection_state()
	if bool(profile_view.get("profile_created", false)):
		var display_name: String = str(profile_view.get("display_name", profile_view.get("name", "Player")))
		var gender_label: String = str(profile_view.get("gender_label", gender))
		summary_label.text = "Profile ready: %s (%s)" % [display_name, gender_label]
	else:
		summary_label.text = "Choose your avatar and enter a player name to continue."


func set_status(text: String) -> void:
	status_label.text = text


func set_bridge_running(is_running: bool) -> void:
	start_bridge_button.disabled = is_running
	reset_button.disabled = not is_running
	create_button.disabled = not is_running


func _on_create_button_pressed() -> void:
	set_status("Status: creating profile...")
	create_profile_requested.emit(name_input.text, _selected_gender())


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
