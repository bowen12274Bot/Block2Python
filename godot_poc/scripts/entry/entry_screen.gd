extends Control
class_name EntryScreen

const CHARACTER_BACKGROUND_PATH := "res://art/C_role/background.png"
const MALE_AVATAR_PATH := "res://art/C_role/MALE.png"
const FEMALE_AVATAR_PATH := "res://art/C_role/female.png"
const CARD_BASE_BORDER := Color(0.72, 0.76, 0.92, 0.35)
const CARD_BASE_FILL := Color(0.05, 0.07, 0.15, 0.72)
const MALE_GLOW_COLOR := Color(0.42, 0.78, 1.0, 1.0)
const FEMALE_GLOW_COLOR := Color(1.0, 0.58, 0.86, 1.0)

signal start_bridge_requested()
signal reset_requested()
signal create_profile_requested(name: String, gender: String)

@onready var background_texture: TextureRect = $BackgroundLayer/BackgroundTexture
@onready var male_art_slot: TextureRect = $ContentLayer/ContentCenter/ContentStack/CharacterSelectLayer/CharacterRow/MaleCard/MaleCardMargin/MaleCardRoot/MaleArtSlot
@onready var female_art_slot: TextureRect = $ContentLayer/ContentCenter/ContentStack/CharacterSelectLayer/CharacterRow/FemaleCard/FemaleCardMargin/FemaleCardRoot/FemaleArtSlot
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
	_apply_background_texture()
	_apply_avatar_texture(male_art_slot, MALE_AVATAR_PATH)
	_apply_avatar_texture(female_art_slot, FEMALE_AVATAR_PATH)
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
	name_input.editable = false
	_refresh_selection_state()
	call_deferred("_refresh_form_state")
	set_process(true)


func _process(_delta: float) -> void:
	_update_card_highlight(male_card, male_glow, male_button.button_pressed, MALE_GLOW_COLOR)
	_update_card_highlight(female_card, female_glow, female_button.button_pressed, FEMALE_GLOW_COLOR)


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
	male_card.self_modulate = Color(0.98, 0.98, 1.0, 1.0) if male_button.button_pressed else Color(0.82, 0.84, 0.92, 1.0)
	female_card.self_modulate = Color(1.0, 0.97, 0.99, 1.0) if female_button.button_pressed else Color(0.82, 0.84, 0.92, 1.0)
	_update_card_highlight(male_card, male_glow, male_button.button_pressed, MALE_GLOW_COLOR)
	_update_card_highlight(female_card, female_glow, female_button.button_pressed, FEMALE_GLOW_COLOR)
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
	if not name_available:
		name_input.placeholder_text = "Choose your avatar first"
	else:
		name_input.placeholder_text = "Enter your player name"
	create_button.disabled = _selected_gender() == "" or name_input.text.strip_edges() == ""
	if not bool(summary_label.text.begins_with("Profile ready:")):
		summary_label.text = _entry_hint_text()


func _is_name_input_available() -> bool:
	return _selected_gender() != ""


func _can_submit_profile() -> bool:
	return _selected_gender() != "" and name_input.text.strip_edges() != ""


func _entry_hint_text() -> String:
	if not _bridge_running:
		if _selected_gender() == "" or name_input.text.strip_edges() == "":
			return "Choose your avatar and name first. Bridge will start automatically when you create the profile."
		return "Ready to create. The bridge will start automatically if needed."
	if _selected_gender() == "":
		return "Step 1: choose your avatar."
	if name_input.text.strip_edges() == "":
		return "Step 2: enter your player name."
	return "Step 3: create your character."


func _apply_background_texture() -> void:
	if ResourceLoader.exists(CHARACTER_BACKGROUND_PATH):
		background_texture.texture = load(CHARACTER_BACKGROUND_PATH)
		return

	var absolute_path: String = ProjectSettings.globalize_path(CHARACTER_BACKGROUND_PATH)
	if not FileAccess.file_exists(absolute_path):
		return

	var image: Image = Image.load_from_file(absolute_path)
	if image == null or image.is_empty():
		return

	background_texture.texture = ImageTexture.create_from_image(image)


func _apply_avatar_texture(target: TextureRect, resource_path: String) -> void:
	if ResourceLoader.exists(resource_path):
		target.texture = load(resource_path)
		return

	var absolute_path: String = ProjectSettings.globalize_path(resource_path)
	if not FileAccess.file_exists(absolute_path):
		return

	var image: Image = _load_image_with_header_fallback(absolute_path)
	if image == null or image.is_empty():
		return

	target.texture = ImageTexture.create_from_image(image)


func _update_card_highlight(card: PanelContainer, glow_bar: ColorRect, is_selected: bool, glow_color: Color) -> void:
	var pulse := 0.72 + 0.28 * (sin(Time.get_ticks_msec() / 240.0) * 0.5 + 0.5)
	var border_color := CARD_BASE_BORDER
	var shadow_color := Color(0.0, 0.0, 0.0, 0.18)
	var background_color := CARD_BASE_FILL
	var border_width := 2
	var shadow_size := 6

	if is_selected:
		border_color = glow_color.lerp(Color(1, 1, 1, 1), 0.22)
		border_color.a = 0.72 + 0.28 * pulse
		shadow_color = glow_color.darkened(0.2)
		shadow_color.a = 0.18 + 0.18 * pulse
		background_color = CARD_BASE_FILL.lerp(glow_color, 0.12)
		background_color.a = 0.84
		border_width = 4
		shadow_size = 16

	var style := StyleBoxFlat.new()
	style.bg_color = background_color
	style.border_color = border_color
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_right = 18
	style.corner_radius_bottom_left = 18
	style.shadow_color = shadow_color
	style.shadow_size = shadow_size
	card.add_theme_stylebox_override("panel", style)

	glow_bar.visible = is_selected
	glow_bar.color = glow_color.lightened(0.12)
	glow_bar.color.a = 0.78 + 0.22 * pulse if is_selected else 0.0
	glow_bar.custom_minimum_size = Vector2(0, 8 + 4 * pulse)


func _load_image_with_header_fallback(absolute_path: String) -> Image:
	var image: Image = Image.load_from_file(absolute_path)
	if image != null and not image.is_empty():
		return image

	var file := FileAccess.open(absolute_path, FileAccess.READ)
	if file == null:
		return image

	var buffer: PackedByteArray = file.get_buffer(file.get_length())
	if buffer.size() < 8:
		return image

	var png_signature := PackedByteArray([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
	if buffer.slice(0, 8) == png_signature:
		var png_image := Image.new()
		if png_image.load_png_from_buffer(buffer) == OK:
			return png_image

	var jpg_image := Image.new()
	if jpg_image.load_jpg_from_buffer(buffer) == OK:
		return jpg_image

	return image
