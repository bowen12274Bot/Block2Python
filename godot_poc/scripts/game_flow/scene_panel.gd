@tool
extends PanelContainer
class_name ScenePanel

signal continue_requested()

const PLACEHOLDER_LEFT_COLOR := Color(0.31, 0.59, 0.96, 0.42)
const PLACEHOLDER_CENTER_COLOR := Color(0.90, 0.72, 0.34, 0.40)
const PLACEHOLDER_RIGHT_COLOR := Color(0.40, 0.53, 0.96, 0.38)

@export_group("Texture Mapping")
@export var background_texture_paths: Dictionary = {}
@export var portrait_texture_paths: Dictionary = {}
@export var expression_texture_paths: Dictionary = {}
@export var default_background_texture: Texture2D
@export var default_left_actor_texture: Texture2D
@export var default_center_actor_texture: Texture2D
@export var default_right_actor_texture: Texture2D
@export var nameplate_frame_texture: Texture2D
@export var left_decor_texture: Texture2D
@export var right_decor_texture: Texture2D

@export_group("Editor Preview")
@export var editor_preview_enabled: bool = true
@export var editor_preview_title: String = "Opening Mission"
@export var editor_preview_speaker: String = "Byte"
@export_multiline var editor_preview_text: String = "Welcome to Code Planet. The system core is unstable."
@export_enum("left", "center", "right") var editor_preview_speaker_side: String = "left"
@export var editor_preview_continue_hint: String = "Click to continue"
@export var editor_preview_use_shared_actor_slot: bool = false
@export_enum("left", "center", "right") var editor_preview_shared_actor_slot: String = "center"
@export var editor_preview_show_calibration_stack: bool = true
@export_subgroup("Preview Left Actor")
@export var editor_preview_left_actor_enabled: bool = true
@export var editor_preview_left_actor_name: String = "Byte"
@export var editor_preview_left_actor_portrait_id: String = "byte-default"
@export var editor_preview_left_actor_expression_id: String = ""
@export_enum("focus", "dim", "silhouette", "hidden") var editor_preview_left_actor_visual_state: String = "focus"
@export_subgroup("Preview Center Actor")
@export var editor_preview_center_actor_enabled: bool = false
@export var editor_preview_center_actor_name: String = "System"
@export var editor_preview_center_actor_portrait_id: String = "system-default"
@export var editor_preview_center_actor_expression_id: String = "confused"
@export_enum("focus", "dim", "silhouette", "hidden") var editor_preview_center_actor_visual_state: String = "focus"
@export_subgroup("Preview Right Actor")
@export var editor_preview_right_actor_enabled: bool = false
@export var editor_preview_right_actor_name: String = "Player"
@export var editor_preview_right_actor_portrait_id: String = "player-default"
@export var editor_preview_right_actor_expression_id: String = ""
@export_enum("focus", "dim", "silhouette", "hidden") var editor_preview_right_actor_visual_state: String = "dim"

@export_group("Dialogue Box Style")
@export var dialogue_box_fill_color := Color(0.10, 0.15, 0.28, 0.76)
@export var dialogue_box_border_color := Color(0.45, 0.80, 1.0, 0.70)
@export_range(0, 12, 1) var dialogue_box_border_width: int = 2
@export_range(0, 48, 1) var dialogue_box_corner_radius: int = 28
@export var dialogue_box_shadow_color := Color(0.01, 0.03, 0.08, 0.42)
@export_range(0, 48, 1) var dialogue_box_shadow_size: int = 18
@export var dialogue_box_content_padding := Vector2i(30, 24)
@export_range(80, 320, 1) var dialogue_box_min_height: int = 170

@export_group("Dialogue Text")
@export var dialogue_text_color := Color(0.95, 0.97, 1.0, 0.98)
@export_range(14, 48, 1) var dialogue_font_size: int = 26
@export_range(0, 32, 1) var dialogue_line_separation: int = 8
@export_range(40, 240, 1) var dialogue_text_min_height: int = 96
@export var meta_text_color := Color(0.70, 0.80, 0.96, 0.86)
@export_range(10, 24, 1) var meta_font_size: int = 13
@export var continue_hint_color := Color(0.59, 0.91, 1.0, 0.96)
@export_range(10, 24, 1) var continue_hint_font_size: int = 16
@export var continue_hint_blink_enabled: bool = true
@export_range(0.1, 6.0, 0.1) var continue_hint_blink_speed: float = 0.7
@export var show_dialogue_meta: bool = false

@export_group("Nameplate")
@export var nameplate_fill_color := Color(0.07, 0.13, 0.24, 0.86)
@export var nameplate_border_color := Color(0.45, 0.86, 1.0, 0.82)
@export_range(0, 12, 1) var nameplate_border_width: int = 2
@export_range(0, 32, 1) var nameplate_corner_radius: int = 18
@export var nameplate_text_color := Color(0.89, 0.98, 1.0, 1.0)
@export_range(12, 34, 1) var nameplate_font_size: int = 24
@export var nameplate_min_size := Vector2(220, 64)

@export_group("Background")
@export var background_fallback_color := Color(0.09, 0.07, 0.17, 1.0)
@export var background_overlay_color := Color(0.02, 0.03, 0.10, 0.22)

@export_group("Actor Presentation")
@export var actor_focus_scale := Vector2(1.03, 1.03)
@export_range(0.1, 1.0, 0.05) var actor_dim_alpha: float = 0.50
@export_range(0.1, 1.0, 0.05) var actor_silhouette_alpha: float = 0.85
@export_range(0.0, 1.0, 0.05) var actor_hidden_alpha: float = 0.0
@export var silhouette_overlay_color := Color(0.03, 0.04, 0.08, 0.68)
@export var left_placeholder_color := PLACEHOLDER_LEFT_COLOR
@export var center_placeholder_color := PLACEHOLDER_CENTER_COLOR
@export var right_placeholder_color := PLACEHOLDER_RIGHT_COLOR
@export var flip_left_actor: bool = false
@export var flip_center_actor: bool = false
@export var flip_right_actor: bool = false

@export_group("Actor Calibration")
@export var portrait_position_offsets: Dictionary = {}
@export var portrait_scale_overrides: Dictionary = {}
@export var expression_position_offsets: Dictionary = {}
@export var expression_scale_overrides: Dictionary = {}

@onready var title_label: Label = $LayoutMargin/SceneRoot/TopBar/SceneTitle
@onready var index_label: Label = $LayoutMargin/SceneRoot/TopBar/IndexLabel
@onready var character_layer: Control = $LayoutMargin/SceneRoot/Stage/CharacterLayer
@onready var background_texture: TextureRect = $LayoutMargin/SceneRoot/Stage/BackgroundLayer/BackgroundTexture
@onready var background_fallback: ColorRect = $LayoutMargin/SceneRoot/Stage/BackgroundLayer/BackgroundFallback
@onready var background_overlay: ColorRect = $LayoutMargin/SceneRoot/Stage/BackgroundLayer/BackgroundOverlay
@onready var left_decor: TextureRect = $LayoutMargin/SceneRoot/Stage/BackgroundLayer/LeftDecor
@onready var right_decor: TextureRect = $LayoutMargin/SceneRoot/Stage/BackgroundLayer/RightDecor
@onready var left_actor_root: Control = $LayoutMargin/SceneRoot/Stage/CharacterLayer/LeftActorAnchor/LeftActorRoot
@onready var left_actor_texture: TextureRect = $LayoutMargin/SceneRoot/Stage/CharacterLayer/LeftActorAnchor/LeftActorRoot/ActorTexture
@onready var left_actor_placeholder: Label = $LayoutMargin/SceneRoot/Stage/CharacterLayer/LeftActorAnchor/LeftActorRoot/PlaceholderLabel
@onready var left_actor_silhouette: ColorRect = $LayoutMargin/SceneRoot/Stage/CharacterLayer/LeftActorAnchor/LeftActorRoot/SilhouetteOverlay
@onready var center_actor_root: Control = $LayoutMargin/SceneRoot/Stage/CharacterLayer/CenterActorAnchor/CenterActorRoot
@onready var center_actor_texture: TextureRect = $LayoutMargin/SceneRoot/Stage/CharacterLayer/CenterActorAnchor/CenterActorRoot/ActorTexture
@onready var center_actor_placeholder: Label = $LayoutMargin/SceneRoot/Stage/CharacterLayer/CenterActorAnchor/CenterActorRoot/PlaceholderLabel
@onready var center_actor_silhouette: ColorRect = $LayoutMargin/SceneRoot/Stage/CharacterLayer/CenterActorAnchor/CenterActorRoot/SilhouetteOverlay
@onready var right_actor_root: Control = $LayoutMargin/SceneRoot/Stage/CharacterLayer/RightActorAnchor/RightActorRoot
@onready var right_actor_texture: TextureRect = $LayoutMargin/SceneRoot/Stage/CharacterLayer/RightActorAnchor/RightActorRoot/ActorTexture
@onready var right_actor_placeholder: Label = $LayoutMargin/SceneRoot/Stage/CharacterLayer/RightActorAnchor/RightActorRoot/PlaceholderLabel
@onready var right_actor_silhouette: ColorRect = $LayoutMargin/SceneRoot/Stage/CharacterLayer/RightActorAnchor/RightActorRoot/SilhouetteOverlay
@onready var left_nameplate_root: Control = $LayoutMargin/SceneRoot/Stage/DialogueLayer/LeftNameplateRoot
@onready var left_nameplate_frame: TextureRect = $LayoutMargin/SceneRoot/Stage/DialogueLayer/LeftNameplateRoot/NameplateFrame
@onready var left_nameplate_fallback: PanelContainer = $LayoutMargin/SceneRoot/Stage/DialogueLayer/LeftNameplateRoot/NameplateFallback
@onready var left_speaker_label: Label = $LayoutMargin/SceneRoot/Stage/DialogueLayer/LeftNameplateRoot/SpeakerLabel
@onready var center_nameplate_root: Control = $LayoutMargin/SceneRoot/Stage/DialogueLayer/CenterNameplateRoot
@onready var center_nameplate_frame: TextureRect = $LayoutMargin/SceneRoot/Stage/DialogueLayer/CenterNameplateRoot/NameplateFrame
@onready var center_nameplate_fallback: PanelContainer = $LayoutMargin/SceneRoot/Stage/DialogueLayer/CenterNameplateRoot/NameplateFallback
@onready var center_speaker_label: Label = $LayoutMargin/SceneRoot/Stage/DialogueLayer/CenterNameplateRoot/SpeakerLabel
@onready var right_nameplate_root: Control = $LayoutMargin/SceneRoot/Stage/DialogueLayer/RightNameplateRoot
@onready var right_nameplate_frame: TextureRect = $LayoutMargin/SceneRoot/Stage/DialogueLayer/RightNameplateRoot/NameplateFrame
@onready var right_nameplate_fallback: PanelContainer = $LayoutMargin/SceneRoot/Stage/DialogueLayer/RightNameplateRoot/NameplateFallback
@onready var right_speaker_label: Label = $LayoutMargin/SceneRoot/Stage/DialogueLayer/RightNameplateRoot/SpeakerLabel
@onready var dialogue_panel: PanelContainer = $LayoutMargin/SceneRoot/Stage/DialogueLayer/DialoguePanel
@onready var dialogue_margin: MarginContainer = $LayoutMargin/SceneRoot/Stage/DialogueLayer/DialoguePanel/DialogueMargin
@onready var dialogue_text: RichTextLabel = $LayoutMargin/SceneRoot/Stage/DialogueLayer/DialoguePanel/DialogueMargin/DialogueRoot/DialogueText
@onready var speaker_side_label: Label = $LayoutMargin/SceneRoot/Stage/DialogueLayer/DialoguePanel/DialogueMargin/DialogueRoot/DialogueMeta/SpeakerSideLabel
@onready var continue_hint_label: Label = $LayoutMargin/SceneRoot/Stage/DialogueLayer/ContinueHintLabel

var _scene_view: Dictionary = {}
var _dialogue_blocks: Array[Dictionary] = []
var _current_index: int = 0
var _editor_preview_signature: String = ""
var _actor_base_positions: Dictionary = {}
var _actor_base_scales: Dictionary = {}
var _editor_calibration_stack_root: Control
var _editor_preview_actor_nodes: Dictionary = {}


func _ready() -> void:
	_store_actor_bases()
	if Engine.is_editor_hint():
		_ensure_editor_preview_actor_nodes()
	_configure_dialogue_click_area()
	dialogue_panel.gui_input.connect(_on_dialogue_panel_gui_input)
	_apply_visual_configuration()
	_apply_decor_textures()
	set_process(true)
	if Engine.is_editor_hint():
		_refresh_editor_preview()


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		_refresh_editor_preview()
	if continue_hint_blink_enabled and continue_hint_label.visible:
		var wave: float = 0.68 + 0.32 * sin(Time.get_ticks_msec() / 1000.0 * TAU * continue_hint_blink_speed)
		var modulate_color := continue_hint_color
		modulate_color.a *= clampf(wave, 0.18, 1.0)
		continue_hint_label.modulate = modulate_color
	else:
		continue_hint_label.modulate = continue_hint_color


func _refresh_editor_preview() -> void:
	if not Engine.is_editor_hint() or not is_node_ready():
		return
	if not editor_preview_enabled:
		return
	var signature_parts := [
		editor_preview_title,
		editor_preview_speaker,
		editor_preview_text,
		editor_preview_speaker_side,
		editor_preview_continue_hint,
		str(editor_preview_use_shared_actor_slot),
		editor_preview_shared_actor_slot,
		str(editor_preview_show_calibration_stack),
		str(editor_preview_left_actor_enabled),
		editor_preview_left_actor_name,
		editor_preview_left_actor_portrait_id,
		editor_preview_left_actor_expression_id,
		editor_preview_left_actor_visual_state,
		str(editor_preview_center_actor_enabled),
		editor_preview_center_actor_name,
		editor_preview_center_actor_portrait_id,
		editor_preview_center_actor_expression_id,
		editor_preview_center_actor_visual_state,
		str(editor_preview_right_actor_enabled),
		editor_preview_right_actor_name,
		editor_preview_right_actor_portrait_id,
		editor_preview_right_actor_expression_id,
		editor_preview_right_actor_visual_state,
		str(dialogue_box_fill_color),
		str(dialogue_box_border_color),
		str(nameplate_frame_texture),
		str(nameplate_min_size),
		str(dialogue_box_content_padding),
	]
	var signature := "|".join(signature_parts)
	if signature == _editor_preview_signature:
		_apply_visual_configuration()
		if not _dialogue_blocks.is_empty():
			_render_current_dialogue()
		_refresh_editor_calibration_stack()
		return
	_editor_preview_signature = signature
	show_scene({
		"title": editor_preview_title,
		"current_index": 0,
		"dialogue_blocks": [{
			"speaker": editor_preview_speaker,
			"text": editor_preview_text,
			"speaker_side": editor_preview_speaker_side,
			"emphasis": "normal",
			"left_actor": _build_editor_preview_actor("left"),
			"center_actor": _build_editor_preview_actor("center"),
			"right_actor": _build_editor_preview_actor("right"),
		}],
		"continue_hint_text": editor_preview_continue_hint,
	})
	_refresh_editor_calibration_stack()


func _build_editor_preview_actor(side: String) -> Dictionary:
	if editor_preview_show_calibration_stack:
		return {
			"display_name": "",
			"portrait_id": "",
			"expression_id": "",
			"visual_state": "hidden",
			"side": side,
		}
	match side:
		"center":
			return {
				"display_name": editor_preview_center_actor_name,
				"portrait_id": editor_preview_center_actor_portrait_id,
				"expression_id": editor_preview_center_actor_expression_id,
				"visual_state": editor_preview_center_actor_visual_state if editor_preview_center_actor_enabled else "hidden",
				"side": "center",
			}
		"right":
			return {
				"display_name": editor_preview_right_actor_name,
				"portrait_id": editor_preview_right_actor_portrait_id,
				"expression_id": editor_preview_right_actor_expression_id,
				"visual_state": editor_preview_right_actor_visual_state if editor_preview_right_actor_enabled else "hidden",
				"side": "right",
			}
		_:
			return {
				"display_name": editor_preview_left_actor_name,
				"portrait_id": editor_preview_left_actor_portrait_id,
				"expression_id": editor_preview_left_actor_expression_id,
				"visual_state": editor_preview_left_actor_visual_state if editor_preview_left_actor_enabled else "hidden",
				"side": "left",
			}


func show_scene(scene_view: Dictionary) -> void:
	_scene_view = scene_view.duplicate(true)
	_dialogue_blocks = _dialogue_array_from_view(_scene_view)
	_current_index = clampi(int(_scene_view.get("current_index", 0)), 0, max(_dialogue_blocks.size() - 1, 0))
	_apply_visual_configuration()
	_render_current_dialogue()


func show_placeholder(message: String) -> void:
	show_scene({
		"title": "Scene",
		"dialogue": {
			"speaker": "Narrator",
			"text": message,
			"speaker_side": "left",
			"emphasis": "normal",
		},
		"continue_hint_text": "Click to continue",
	})


func set_status_overlay(_text: String) -> void:
	pass


func can_continue_story() -> bool:
	return not _dialogue_blocks.is_empty()


func continue_story() -> bool:
	if _dialogue_blocks.is_empty():
		return true
	if _current_index < _dialogue_blocks.size() - 1:
		_current_index += 1
		_render_current_dialogue()
		return false
	return true


func is_last_dialogue() -> bool:
	return not _dialogue_blocks.is_empty() and _current_index >= _dialogue_blocks.size() - 1


func _apply_visual_configuration() -> void:
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_apply_background_configuration()
	_apply_dialogue_panel_style()
	_apply_nameplate_style()
	_apply_text_configuration()
	_apply_actor_placeholder_defaults()


func _apply_background_configuration() -> void:
	background_fallback.color = background_fallback_color
	background_overlay.color = background_overlay_color


func _apply_dialogue_panel_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = dialogue_box_fill_color
	style.border_color = dialogue_box_border_color
	style.set_border_width_all(dialogue_box_border_width)
	style.set_corner_radius_all(dialogue_box_corner_radius)
	style.shadow_color = dialogue_box_shadow_color
	style.shadow_size = dialogue_box_shadow_size
	dialogue_panel.add_theme_stylebox_override("panel", style)
	dialogue_panel.custom_minimum_size = Vector2(dialogue_panel.custom_minimum_size.x, dialogue_box_min_height)
	dialogue_margin.add_theme_constant_override("margin_left", dialogue_box_content_padding.x)
	dialogue_margin.add_theme_constant_override("margin_top", dialogue_box_content_padding.y)
	dialogue_margin.add_theme_constant_override("margin_right", dialogue_box_content_padding.x)
	dialogue_margin.add_theme_constant_override("margin_bottom", dialogue_box_content_padding.y)


func _apply_nameplate_style() -> void:
	_apply_nameplate_style_to_root(left_nameplate_root, left_nameplate_frame, left_nameplate_fallback)
	_apply_nameplate_style_to_root(center_nameplate_root, center_nameplate_frame, center_nameplate_fallback)
	_apply_nameplate_style_to_root(right_nameplate_root, right_nameplate_frame, right_nameplate_fallback)


func _apply_nameplate_style_to_root(root: Control, frame: TextureRect, fallback: PanelContainer) -> void:
	root.custom_minimum_size = nameplate_min_size
	root.size = nameplate_min_size
	frame.texture = nameplate_frame_texture
	frame.visible = nameplate_frame_texture != null
	fallback.visible = nameplate_frame_texture == null
	var style := StyleBoxFlat.new()
	style.bg_color = nameplate_fill_color
	style.border_color = nameplate_border_color
	style.set_border_width_all(nameplate_border_width)
	style.set_corner_radius_all(nameplate_corner_radius)
	fallback.add_theme_stylebox_override("panel", style)


func _apply_text_configuration() -> void:
	dialogue_text.custom_minimum_size = Vector2(0, dialogue_text_min_height)
	dialogue_text.add_theme_font_size_override("normal_font_size", dialogue_font_size)
	dialogue_text.add_theme_color_override("default_color", dialogue_text_color)
	dialogue_text.add_theme_constant_override("line_separation", dialogue_line_separation)
	_apply_nameplate_label_style(left_speaker_label)
	_apply_nameplate_label_style(center_speaker_label)
	_apply_nameplate_label_style(right_speaker_label)
	speaker_side_label.add_theme_font_size_override("font_size", meta_font_size)
	speaker_side_label.modulate = meta_text_color
	speaker_side_label.visible = show_dialogue_meta
	continue_hint_label.add_theme_font_size_override("font_size", continue_hint_font_size)
	continue_hint_label.modulate = continue_hint_color


func _apply_nameplate_label_style(label: Label) -> void:
	label.add_theme_font_size_override("font_size", nameplate_font_size)
	label.add_theme_color_override("font_color", nameplate_text_color)


func _apply_actor_placeholder_defaults() -> void:
	left_actor_placeholder.modulate = left_placeholder_color
	center_actor_placeholder.modulate = center_placeholder_color
	right_actor_placeholder.modulate = right_placeholder_color
	left_actor_silhouette.color = silhouette_overlay_color
	center_actor_silhouette.color = silhouette_overlay_color
	right_actor_silhouette.color = silhouette_overlay_color


func _apply_decor_textures() -> void:
	left_decor.texture = left_decor_texture
	left_decor.visible = left_decor_texture != null
	right_decor.texture = right_decor_texture
	right_decor.visible = right_decor_texture != null


func _render_current_dialogue() -> void:
	title_label.text = str(_scene_view.get("title", "Scene"))
	index_label.text = _build_index_label()
	var current_dialogue: Dictionary = {}
	if not _dialogue_blocks.is_empty():
		current_dialogue = _dialogue_blocks[_current_index]
	var current_scene_view := _current_scene_view(current_dialogue)
	_apply_background_view(current_scene_view.get("background", {}))
	var left_nodes := _actor_nodes("left")
	var center_nodes := _actor_nodes("center")
	var right_nodes := _actor_nodes("right")
	_apply_actor_view(_actor_view_for_side("left", current_dialogue), left_nodes["root"], left_nodes["texture"], left_nodes["placeholder"], left_nodes["silhouette"], "left")
	_apply_actor_view(_actor_view_for_side("center", current_dialogue), center_nodes["root"], center_nodes["texture"], center_nodes["placeholder"], center_nodes["silhouette"], "center")
	_apply_actor_view(_actor_view_for_side("right", current_dialogue), right_nodes["root"], right_nodes["texture"], right_nodes["placeholder"], right_nodes["silhouette"], "right")
	_apply_dialogue_view(current_dialogue, current_scene_view)


func _build_index_label() -> String:
	var total_blocks: int = _dialogue_blocks.size()
	if total_blocks <= 0:
		return ""
	return "%d / %d" % [_current_index + 1, total_blocks]


func _apply_background_view(background_value: Variant) -> void:
	var background: Dictionary = background_value if background_value is Dictionary else {}
	var texture := _resolve_background_texture(background)
	background_texture.texture = texture
	background_texture.visible = texture != null
	background_fallback.visible = texture == null


func _refresh_editor_calibration_stack() -> void:
	if not Engine.is_editor_hint() or not is_node_ready():
		return
	var root := _ensure_editor_calibration_stack_root()
	root.visible = editor_preview_enabled and editor_preview_show_calibration_stack
	if not root.visible:
		return
	var base_side := _preview_actor_base_side("center")
	var base_position: Vector2 = _actor_base_positions.get(base_side, Vector2.ZERO)
	var base_scale: Vector2 = _actor_base_scales.get(base_side, Vector2.ONE)
	var base_size := center_actor_root.size if base_side == "center" else (left_actor_root.size if base_side == "left" else right_actor_root.size)
	var preview_defs := [
		{"node": "BytePreview", "portrait_id": "byte-default", "expression_id": "", "modulate": Color(1, 1, 1, 0.92)},
		{"node": "SystemPreview", "portrait_id": "system-default", "expression_id": "confused", "modulate": Color(1, 0.98, 0.92, 0.78)},
		{"node": "PlayerFemalePreview", "portrait_id": "player-female-default", "expression_id": "", "modulate": Color(0.96, 1, 1, 0.72)},
		{"node": "PlayerMalePreview", "portrait_id": "player-male-default", "expression_id": "", "modulate": Color(1, 0.96, 1, 0.72)},
		{"node": "BugKingPreview", "portrait_id": "bug-king-default", "expression_id": "", "modulate": Color(1, 0.94, 0.94, 0.72)},
	]
	for preview_def in preview_defs:
		var preview_node: TextureRect = root.get_node(str(preview_def["node"]))
		var actor := {
			"portrait_id": str(preview_def["portrait_id"]),
			"expression_id": str(preview_def["expression_id"]),
		}
		preview_node.texture = _resolve_actor_texture(actor, base_side)
		preview_node.visible = preview_node.texture != null
		preview_node.position = base_position + _resolve_actor_position_offset(actor)
		preview_node.size = base_size
		preview_node.scale = _resolve_actor_scale(actor) * base_scale
		preview_node.modulate = preview_def["modulate"]
		preview_node.flip_h = _is_actor_flipped(base_side)


func _ensure_editor_calibration_stack_root() -> Control:
	if _editor_calibration_stack_root != null:
		return _editor_calibration_stack_root
	_editor_calibration_stack_root = Control.new()
	_editor_calibration_stack_root.name = "EditorCalibrationStack"
	_editor_calibration_stack_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_editor_calibration_stack_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	character_layer.add_child(_editor_calibration_stack_root)
	for node_name in ["BytePreview", "SystemPreview", "PlayerFemalePreview", "PlayerMalePreview", "BugKingPreview"]:
		var preview_node := TextureRect.new()
		preview_node.name = node_name
		preview_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		preview_node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview_node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_editor_calibration_stack_root.add_child(preview_node)
	return _editor_calibration_stack_root


func _ensure_editor_preview_actor_nodes() -> void:
	if not _editor_preview_actor_nodes.is_empty():
		return
	for side in ["left", "center", "right"]:
		var source_root: Control = {"left": left_actor_root, "center": center_actor_root, "right": right_actor_root}[side]
		var parent_node: Node = source_root.get_parent()
		var preview_root := source_root.duplicate() as Control
		preview_root.name = "EditorPreview%sActorRoot" % side.capitalize()
		preview_root.owner = null
		parent_node.add_child(preview_root)
		var preview_texture := preview_root.get_node("ActorTexture") as TextureRect
		var preview_placeholder := preview_root.get_node("PlaceholderLabel") as Label
		var preview_silhouette := preview_root.get_node("SilhouetteOverlay") as ColorRect
		_editor_preview_actor_nodes[side] = {
			"root": preview_root,
			"texture": preview_texture,
			"placeholder": preview_placeholder,
			"silhouette": preview_silhouette,
		}
	left_actor_root.visible = false
	center_actor_root.visible = false
	right_actor_root.visible = false


func _actor_nodes(side: String) -> Dictionary:
	if Engine.is_editor_hint():
		_ensure_editor_preview_actor_nodes()
		if _editor_preview_actor_nodes.has(side):
			return _editor_preview_actor_nodes[side]
	match side:
		"center":
			return {"root": center_actor_root, "texture": center_actor_texture, "placeholder": center_actor_placeholder, "silhouette": center_actor_silhouette}
		"right":
			return {"root": right_actor_root, "texture": right_actor_texture, "placeholder": right_actor_placeholder, "silhouette": right_actor_silhouette}
		_:
			return {"root": left_actor_root, "texture": left_actor_texture, "placeholder": left_actor_placeholder, "silhouette": left_actor_silhouette}


func _preview_actor_base_side(side: String) -> String:
	if Engine.is_editor_hint() and editor_preview_show_calibration_stack and editor_preview_use_shared_actor_slot:
		if editor_preview_shared_actor_slot in ["left", "center", "right"]:
			return editor_preview_shared_actor_slot
	return side


func _apply_actor_view(actor_value: Variant, actor_root: Control, actor_texture: TextureRect, placeholder: Label, silhouette: ColorRect, side: String) -> void:
	var actor: Dictionary = actor_value if actor_value is Dictionary else {}
	var visual_state: String = str(actor.get("visual_state", "hidden"))
	var texture := _resolve_actor_texture(actor, side)
	var display_name: String = str(actor.get("display_name", ""))
	var base_side := _preview_actor_base_side(side)
	var base_position: Vector2 = _actor_base_positions.get(base_side, actor_root.position)
	var base_scale: Vector2 = _actor_base_scales.get(base_side, Vector2.ONE)
	var actor_offset: Vector2 = _resolve_actor_position_offset(actor)
	var calibrated_scale: Vector2 = _resolve_actor_scale(actor) * base_scale
	if display_name == "":
		display_name = side.capitalize()
	actor_root.position = base_position + actor_offset
	actor_texture.texture = texture
	actor_texture.flip_h = _is_actor_flipped(side)
	placeholder.text = display_name
	placeholder.visible = texture == null and visual_state != "hidden"
	actor_texture.visible = texture != null and visual_state != "hidden"
	silhouette.visible = visual_state == "silhouette"
	match visual_state:
		"focus":
			actor_root.visible = true
			actor_root.modulate = Color(1, 1, 1, 1)
			actor_root.scale = Vector2(calibrated_scale.x * actor_focus_scale.x, calibrated_scale.y * actor_focus_scale.y)
			placeholder.modulate.a = 0.92
		"dim":
			actor_root.visible = true
			actor_root.modulate = Color(1, 1, 1, actor_dim_alpha)
			actor_root.scale = calibrated_scale
			placeholder.modulate.a = actor_dim_alpha
		"silhouette":
			actor_root.visible = true
			actor_root.modulate = Color(1, 1, 1, actor_silhouette_alpha)
			actor_root.scale = calibrated_scale
			placeholder.modulate.a = actor_silhouette_alpha
		"hidden":
			actor_root.visible = false
			actor_root.modulate = Color(1, 1, 1, actor_hidden_alpha)
			actor_root.scale = calibrated_scale
			placeholder.modulate.a = 0.0
		_:
			actor_root.visible = true
			actor_root.modulate = Color(1, 1, 1, 1)
			actor_root.scale = calibrated_scale
			placeholder.modulate.a = 0.88


func _store_actor_bases() -> void:
	_actor_base_positions = {
		"left": left_actor_root.position,
		"center": center_actor_root.position,
		"right": right_actor_root.position,
	}
	_actor_base_scales = {
		"left": left_actor_root.scale,
		"center": center_actor_root.scale,
		"right": right_actor_root.scale,
	}


func _resolve_actor_position_offset(actor: Dictionary) -> Vector2:
	var expression_key := _actor_expression_key(actor)
	var expression_offset := _vector2_from_variant(expression_position_offsets.get(expression_key, null), Vector2.ZERO)
	if expression_offset != Vector2.ZERO:
		return expression_offset
	var portrait_id: String = str(actor.get("portrait_id", ""))
	return _vector2_from_variant(portrait_position_offsets.get(portrait_id, null), Vector2.ZERO)


func _resolve_actor_scale(actor: Dictionary) -> Vector2:
	var expression_key := _actor_expression_key(actor)
	var expression_scale := _scale_from_variant(expression_scale_overrides.get(expression_key, null), Vector2.ONE)
	if expression_scale != Vector2.ONE:
		return expression_scale
	var portrait_id: String = str(actor.get("portrait_id", ""))
	return _scale_from_variant(portrait_scale_overrides.get(portrait_id, null), Vector2.ONE)


func _actor_expression_key(actor: Dictionary) -> String:
	var portrait_id: String = str(actor.get("portrait_id", ""))
	var expression_id: String = str(actor.get("expression_id", ""))
	if portrait_id == "" or expression_id == "":
		return ""
	return "%s:%s" % [portrait_id, expression_id]


func _vector2_from_variant(value: Variant, fallback: Vector2) -> Vector2:
	if value is Vector2:
		return value
	if value is Array and value.size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	return fallback


func _scale_from_variant(value: Variant, fallback: Vector2) -> Vector2:
	if value is Vector2:
		return value
	if value is float or value is int:
		var scalar := float(value)
		return Vector2(scalar, scalar)
	if value is Array and value.size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	return fallback


func _apply_dialogue_view(dialogue_value: Variant, scene_view: Dictionary) -> void:
	var dialogue: Dictionary = dialogue_value if dialogue_value is Dictionary else {}
	var speaker: String = str(dialogue.get("speaker", "Narrator"))
	var text: String = str(dialogue.get("text", "No dialogue available."))
	var speaker_side: String = str(dialogue.get("speaker_side", ""))
	var emphasis: String = str(dialogue.get("emphasis", "normal"))
	dialogue_text.text = text
	speaker_side_label.text = _build_dialogue_meta_text(scene_view, speaker_side, emphasis)
	speaker_side_label.visible = show_dialogue_meta and speaker_side_label.text != ""
	continue_hint_label.text = _continue_hint_text(scene_view)
	continue_hint_label.visible = continue_hint_label.text.strip_edges() != ""
	_apply_nameplate_visibility(speaker, speaker_side)


func _build_dialogue_meta_text(scene_view: Dictionary, speaker_side: String, emphasis: String) -> String:
	var parts: Array[String] = []
	if speaker_side != "":
		parts.append("Speaker: %s" % speaker_side)
	if emphasis != "" and emphasis != "normal":
		parts.append("Tone: %s" % emphasis)
	var background: Variant = scene_view.get("background", {})
	if background is Dictionary:
		var background_id: String = str(background.get("background_id", ""))
		if background_id != "":
			parts.append("BG: %s" % background_id)
	return " | ".join(parts)


func _apply_nameplate_visibility(speaker: String, speaker_side: String) -> void:
	if Engine.is_editor_hint():
		left_nameplate_root.visible = true
		center_nameplate_root.visible = true
		right_nameplate_root.visible = true
		left_speaker_label.text = editor_preview_left_actor_name if editor_preview_left_actor_enabled else "Left"
		center_speaker_label.text = editor_preview_center_actor_name if editor_preview_center_actor_enabled else "Center"
		right_speaker_label.text = editor_preview_right_actor_name if editor_preview_right_actor_enabled else "Right"
		return
	var side := speaker_side if speaker_side in ["left", "center", "right"] else "left"
	var has_speaker := speaker.strip_edges() != ""
	left_nameplate_root.visible = has_speaker and side == "left"
	center_nameplate_root.visible = has_speaker and side == "center"
	right_nameplate_root.visible = has_speaker and side == "right"
	left_speaker_label.text = speaker
	center_speaker_label.text = speaker
	right_speaker_label.text = speaker


func _dialogue_array_from_view(scene_view: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var blocks_value: Variant = scene_view.get("dialogue_blocks", [])
	if blocks_value is Array:
		for block_value in blocks_value:
			if block_value is Dictionary:
				result.append(block_value)
	if result.is_empty():
		var fallback_dialogue: Variant = scene_view.get("dialogue", {})
		if fallback_dialogue is Dictionary and not fallback_dialogue.is_empty():
			result.append(fallback_dialogue)
	return result


func _actor_view_for_side(side: String, dialogue: Dictionary) -> Dictionary:
	var actor_value: Variant = dialogue.get("%s_actor" % side, {})
	if actor_value is Dictionary:
		return actor_value
	var scene_actor_value: Variant = _scene_view.get("%s_actor" % side, {})
	if scene_actor_value is Dictionary:
		return scene_actor_value
	return {}


func _current_scene_view(dialogue: Dictionary) -> Dictionary:
	var current_view: Dictionary = _scene_view.duplicate(true)
	current_view["current_index"] = _current_index
	current_view["total_blocks"] = _dialogue_blocks.size()
	current_view["dialogue"] = dialogue
	current_view["left_actor"] = _actor_view_for_side("left", dialogue)
	current_view["center_actor"] = _actor_view_for_side("center", dialogue)
	current_view["right_actor"] = _actor_view_for_side("right", dialogue)

	var background_view: Dictionary = {}
	var scene_background_value: Variant = _scene_view.get("background", {})
	if scene_background_value is Dictionary:
		background_view = (scene_background_value as Dictionary).duplicate(true)
	background_view["background_id"] = str(dialogue.get("background_id", background_view.get("background_id", "")))
	background_view["image_path"] = str(dialogue.get("background_image_path", background_view.get("image_path", "")))
	current_view["background"] = background_view
	return current_view


func _continue_hint_text(scene_view: Dictionary) -> String:
	if is_last_dialogue():
		return "Continue"
	return str(scene_view.get("continue_hint_text", "Click to continue"))


func _configure_dialogue_click_area() -> void:
	left_speaker_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center_speaker_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right_speaker_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	speaker_side_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialogue_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	continue_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _resolve_background_texture(background: Dictionary) -> Texture2D:
	var image_path: String = str(background.get("image_path", ""))
	if image_path != "":
		var direct_texture := _load_texture(image_path)
		if direct_texture != null:
			return direct_texture
	return _texture_from_mapping(background_texture_paths, str(background.get("background_id", "")), default_background_texture)


func _resolve_actor_texture(actor: Dictionary, side: String) -> Texture2D:
	var image_path: String = str(actor.get("image_path", ""))
	if image_path != "":
		var direct_texture := _load_texture(image_path)
		if direct_texture != null:
			return direct_texture
	var portrait_id: String = str(actor.get("portrait_id", ""))
	var expression_id: String = str(actor.get("expression_id", ""))
	if portrait_id != "" and expression_id != "":
		var expression_key := "%s:%s" % [portrait_id, expression_id]
		var expression_texture := _texture_from_mapping(expression_texture_paths, expression_key, null)
		if expression_texture != null:
			return expression_texture
	var fallback_texture: Texture2D = _default_actor_texture_for_side(side)
	return _texture_from_mapping(portrait_texture_paths, portrait_id, fallback_texture)


func _default_actor_texture_for_side(side: String) -> Texture2D:
	match side:
		"center":
			return default_center_actor_texture
		"right":
			return default_right_actor_texture
		_:
			return default_left_actor_texture


func _is_actor_flipped(side: String) -> bool:
	match side:
		"center":
			return flip_center_actor
		"right":
			return flip_right_actor
		_:
			return flip_left_actor


func _texture_from_mapping(mapping: Dictionary, key: String, fallback: Texture2D) -> Texture2D:
	if key != "" and mapping.has(key):
		var value: Variant = mapping[key]
		if value is Texture2D:
			return value
		if value is String:
			var mapped_texture := _load_texture(str(value))
			if mapped_texture != null:
				return mapped_texture
	return fallback


func _load_texture(resource_path: String) -> Texture2D:
	if resource_path == "":
		return null
	if not ResourceLoader.exists(resource_path):
		return null
	var resource := ResourceLoader.load(resource_path)
	return resource as Texture2D


func _on_dialogue_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		continue_requested.emit()
