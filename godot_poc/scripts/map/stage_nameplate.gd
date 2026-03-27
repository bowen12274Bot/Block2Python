@tool
extends PanelContainer
class_name StageNameplate

@export var stage_number: String = "01":
	set(value):
		stage_number = value
		_sync_content()

@export var stage_title: String = "Stage Title":
	set(value):
		stage_title = value
		_sync_content()

@export var plate_texture: Texture2D:
	set(value):
		plate_texture = value
		_sync_plate_texture()

@export var orbitron_font: FontFile:
	set(value):
		orbitron_font = value
		_apply_fonts()

@onready var plate_art: TextureRect = get_node_or_null("PlateArt")
@onready var plate_placeholder: Label = get_node_or_null("PlatePlaceholder")
@onready var plate_shade: ColorRect = get_node_or_null("PlateShade")
@onready var number_label: Label = get_node_or_null("ContentRoot/NumberLabel") if get_node_or_null("ContentRoot/NumberLabel") != null else get_node_or_null("PlateMargin/PlateRoot/NumberChip/NumberLabel")
@onready var title_label: Label = get_node_or_null("ContentRoot/TitleLabel") if get_node_or_null("ContentRoot/TitleLabel") != null else get_node_or_null("PlateMargin/PlateRoot/TitleLabel")


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_refresh_visuals()


func _enter_tree() -> void:
	if Engine.is_editor_hint():
		call_deferred("_refresh_visuals")


func _refresh_visuals() -> void:
	_sync_plate_texture()
	_sync_content()
	_apply_fonts()


func set_stage_number_text(value: String) -> void:
	stage_number = value
	_sync_content()


func set_stage_title_text(value: String) -> void:
	stage_title = value
	_sync_content()


func set_plate_texture_resource(value: Texture2D) -> void:
	plate_texture = value
	_sync_plate_texture()


func _sync_plate_texture() -> void:
	if plate_art != null:
		plate_art.texture = plate_texture
	if plate_placeholder != null:
		plate_placeholder.visible = plate_texture == null
	if plate_shade != null:
		plate_shade.visible = plate_texture == null


func _sync_content() -> void:
	if number_label != null:
		number_label.text = stage_number
	if title_label != null:
		title_label.text = stage_title


func _apply_fonts() -> void:
	if orbitron_font == null:
		return
	if title_label != null:
		title_label.add_theme_font_override("font", orbitron_font)
