extends Control
class_name QuestMapStage

@onready var header_row: HBoxContainer = $HudLayer/Header
@onready var header_title_column: VBoxContainer = $HudLayer/Header/TitleColumn
@onready var header_title: Label = $HudLayer/Header/TitleColumn/Title
@onready var header_subtitle: Label = $HudLayer/Header/TitleColumn/Subtitle
@onready var background_hint: Label = $BackgroundTexture/BackgroundHint
@onready var route_layer: Control = $RouteLayer
@onready var foreground_hint: Label = $ForegroundTexture/ForegroundHint

var _last_map_view: Dictionary = {}
var _helper_text_override: String = ""


func _ready() -> void:
	route_layer.z_index = 1
	header_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header_title_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header_subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	foreground_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header_row.visible = false
	background_hint.visible = false
	foreground_hint.visible = false
	background_hint.text = "Drop final starfield / map base art here"
	foreground_hint.text = "Optional foreground VFX / clouds / frame art"


func show_map(map_view: Dictionary) -> void:
	_last_map_view = map_view.duplicate(true)
	header_title.text = str(map_view.get("quest_title", "Quest Map"))
	header_subtitle.text = str(map_view.get("summary", "Main map is waiting for route data."))


func set_helper_text(text: String) -> void:
	_helper_text_override = text
