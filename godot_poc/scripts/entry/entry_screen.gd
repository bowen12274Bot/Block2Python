extends Control
class_name EntryScreen

signal start_bridge_requested()
signal reset_requested()
signal create_profile_requested(name: String, gender: String)

@onready var status_label: Label = $Margin/Panel/Content/StatusLabel
@onready var summary_label: Label = $Margin/Panel/Content/SummaryLabel
@onready var start_bridge_button: Button = $Margin/Panel/Content/BridgeButtons/StartBridgeButton
@onready var reset_button: Button = $Margin/Panel/Content/BridgeButtons/ResetButton
@onready var name_input: LineEdit = $Margin/Panel/Content/Form/NameInput
@onready var male_button: CheckBox = $Margin/Panel/Content/Form/GenderRow/MaleButton
@onready var female_button: CheckBox = $Margin/Panel/Content/Form/GenderRow/FemaleButton
@onready var create_button: Button = $Margin/Panel/Content/CreateButton


func _ready() -> void:
	start_bridge_button.pressed.connect(func() -> void:
		start_bridge_requested.emit()
	)
	reset_button.pressed.connect(func() -> void:
		reset_requested.emit()
	)
	create_button.pressed.connect(_on_create_button_pressed)


func show_profile(profile_view: Dictionary) -> void:
	name_input.text = str(profile_view.get("name", ""))
	var gender: String = str(profile_view.get("gender", ""))
	male_button.button_pressed = gender == "male"
	female_button.button_pressed = gender == "female"
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
