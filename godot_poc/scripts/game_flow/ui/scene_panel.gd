@tool
extends PanelContainer
class_name ScenePanel

signal continue_requested()

const ScenePanelEditorPreviewScript = preload("res://scripts/game_flow/ui/scene_panel/scene_panel_editor_preview.gd")
const ScenePanelActorCalibrationScript = preload("res://scripts/game_flow/ui/scene_panel/scene_panel_actor_calibration.gd")
const ScenePanelStyleScript = preload("res://scripts/game_flow/ui/scene_panel/scene_panel_style.gd")
const ScenePanelRuntimeScript = preload("res://scripts/game_flow/ui/scene_panel/scene_panel_runtime.gd")
const ScenePanelAssetResolverScript = preload("res://scripts/game_flow/ui/scene_panel/scene_panel_asset_resolver.gd")
const ScenePanelActorRendererScript = preload("res://scripts/game_flow/ui/scene_panel/scene_panel_actor_renderer.gd")
const ScenePanelEditorNodesScript = preload("res://scripts/game_flow/ui/scene_panel/scene_panel_editor_nodes.gd")
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
	var signature := ScenePanelEditorPreviewScript.build_signature(
		_editor_preview_config(),
		[
			str(dialogue_box_fill_color),
			str(dialogue_box_border_color),
			str(nameplate_frame_texture),
			str(nameplate_min_size),
			str(dialogue_box_content_padding),
		]
	)
	if signature == _editor_preview_signature:
		_apply_visual_configuration()
		if not _dialogue_blocks.is_empty():
			_render_current_dialogue()
		_refresh_editor_calibration_stack()
		return
	_editor_preview_signature = signature
	show_scene(ScenePanelEditorPreviewScript.build_scene_view(_editor_preview_config()))
	_refresh_editor_calibration_stack()


func _build_editor_preview_actor(side: String) -> Dictionary:
	return ScenePanelEditorPreviewScript.build_actor(_editor_preview_config(), side)


func show_scene(scene_view: Dictionary) -> void:
	_scene_view = scene_view.duplicate(true)
	_dialogue_blocks = ScenePanelRuntimeScript.dialogue_array_from_view(_scene_view)
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
	ScenePanelStyleScript.apply_background(background_fallback, background_overlay, background_fallback_color, background_overlay_color)


func _apply_dialogue_panel_style() -> void:
	ScenePanelStyleScript.apply_dialogue_panel(
		dialogue_panel,
		dialogue_margin,
		dialogue_box_fill_color,
		dialogue_box_border_color,
		dialogue_box_border_width,
		dialogue_box_corner_radius,
		dialogue_box_shadow_color,
		dialogue_box_shadow_size,
		dialogue_box_content_padding,
		dialogue_box_min_height
	)


func _apply_nameplate_style() -> void:
	_apply_nameplate_style_to_root(left_nameplate_root, left_nameplate_frame, left_nameplate_fallback)
	_apply_nameplate_style_to_root(center_nameplate_root, center_nameplate_frame, center_nameplate_fallback)
	_apply_nameplate_style_to_root(right_nameplate_root, right_nameplate_frame, right_nameplate_fallback)


func _apply_nameplate_style_to_root(root: Control, frame: TextureRect, fallback: PanelContainer) -> void:
	ScenePanelStyleScript.apply_nameplate(
		root,
		frame,
		fallback,
		nameplate_min_size,
		nameplate_frame_texture,
		nameplate_fill_color,
		nameplate_border_color,
		nameplate_border_width,
		nameplate_corner_radius
	)


func _apply_text_configuration() -> void:
	ScenePanelStyleScript.apply_text(
		dialogue_text,
		speaker_side_label,
		continue_hint_label,
		[left_speaker_label, center_speaker_label, right_speaker_label],
		dialogue_text_min_height,
		dialogue_font_size,
		dialogue_text_color,
		dialogue_line_separation,
		nameplate_font_size,
		nameplate_text_color,
		meta_font_size,
		meta_text_color,
		show_dialogue_meta,
		continue_hint_font_size,
		continue_hint_color
	)


func _apply_actor_placeholder_defaults() -> void:
	ScenePanelStyleScript.apply_actor_placeholders(
		left_actor_placeholder,
		center_actor_placeholder,
		right_actor_placeholder,
		left_actor_silhouette,
		center_actor_silhouette,
		right_actor_silhouette,
		left_placeholder_color,
		center_placeholder_color,
		right_placeholder_color,
		silhouette_overlay_color
	)


func _apply_decor_textures() -> void:
	ScenePanelStyleScript.apply_decor(left_decor, right_decor, left_decor_texture, right_decor_texture)


func _render_current_dialogue() -> void:
	title_label.text = str(_scene_view.get("title", "Scene"))
	index_label.text = ScenePanelRuntimeScript.build_index_label(_current_index, _dialogue_blocks)
	var current_dialogue: Dictionary = {}
	if not _dialogue_blocks.is_empty():
		current_dialogue = _dialogue_blocks[_current_index]
	var current_scene_view := ScenePanelRuntimeScript.current_scene_view(_scene_view, _dialogue_blocks, _current_index, current_dialogue)
	_apply_background_view(current_scene_view.get("background", {}))
	var left_nodes := _actor_nodes("left")
	var center_nodes := _actor_nodes("center")
	var right_nodes := _actor_nodes("right")
	_apply_actor_view(ScenePanelRuntimeScript.actor_view_for_side(_scene_view, "left", current_dialogue), left_nodes["root"], left_nodes["texture"], left_nodes["placeholder"], left_nodes["silhouette"], "left")
	_apply_actor_view(ScenePanelRuntimeScript.actor_view_for_side(_scene_view, "center", current_dialogue), center_nodes["root"], center_nodes["texture"], center_nodes["placeholder"], center_nodes["silhouette"], "center")
	_apply_actor_view(ScenePanelRuntimeScript.actor_view_for_side(_scene_view, "right", current_dialogue), right_nodes["root"], right_nodes["texture"], right_nodes["placeholder"], right_nodes["silhouette"], "right")
	_apply_dialogue_view(current_dialogue, current_scene_view)


func _apply_background_view(background_value: Variant) -> void:
	ScenePanelActorRendererScript.apply_background_view(
		background_value,
		background_texture,
		background_fallback,
		background_texture_paths,
		default_background_texture
	)


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
	for preview_def in ScenePanelEditorPreviewScript.preview_definitions():
		var preview_node: TextureRect = root.get_node(str(preview_def["node"]))
		var actor := {
			"portrait_id": str(preview_def["portrait_id"]),
			"expression_id": str(preview_def["expression_id"]),
		}
		preview_node.texture = ScenePanelAssetResolverScript.resolve_actor_texture(actor, base_side, expression_texture_paths, portrait_texture_paths, default_left_actor_texture, default_center_actor_texture, default_right_actor_texture)
		preview_node.visible = preview_node.texture != null
		preview_node.position = base_position + ScenePanelActorCalibrationScript.resolve_position_offset(actor, expression_position_offsets, portrait_position_offsets)
		preview_node.size = base_size
		preview_node.scale = ScenePanelActorCalibrationScript.resolve_scale(actor, expression_scale_overrides, portrait_scale_overrides) * base_scale
		preview_node.modulate = preview_def["modulate"]
		preview_node.flip_h = ScenePanelAssetResolverScript.is_actor_flipped(base_side, flip_left_actor, flip_center_actor, flip_right_actor)


func _ensure_editor_calibration_stack_root() -> Control:
	_editor_calibration_stack_root = ScenePanelEditorNodesScript.ensure_calibration_stack_root(character_layer, _editor_calibration_stack_root)
	return _editor_calibration_stack_root


func _ensure_editor_preview_actor_nodes() -> void:
	_editor_preview_actor_nodes = ScenePanelEditorNodesScript.ensure_preview_actor_nodes(
		_editor_preview_actor_nodes,
		{
			"left": left_actor_root,
			"center": center_actor_root,
			"right": right_actor_root,
		}
	)


func _actor_nodes(side: String) -> Dictionary:
	if Engine.is_editor_hint():
		_ensure_editor_preview_actor_nodes()
		return ScenePanelEditorNodesScript.actor_nodes(
			side,
			_editor_preview_actor_nodes,
			{
				"left": {"root": left_actor_root, "texture": left_actor_texture, "placeholder": left_actor_placeholder, "silhouette": left_actor_silhouette},
				"center": {"root": center_actor_root, "texture": center_actor_texture, "placeholder": center_actor_placeholder, "silhouette": center_actor_silhouette},
				"right": {"root": right_actor_root, "texture": right_actor_texture, "placeholder": right_actor_placeholder, "silhouette": right_actor_silhouette},
			}
		)
	match side:
		"center":
			return {"root": center_actor_root, "texture": center_actor_texture, "placeholder": center_actor_placeholder, "silhouette": center_actor_silhouette}
		"right":
			return {"root": right_actor_root, "texture": right_actor_texture, "placeholder": right_actor_placeholder, "silhouette": right_actor_silhouette}
		_:
			return {"root": left_actor_root, "texture": left_actor_texture, "placeholder": left_actor_placeholder, "silhouette": left_actor_silhouette}


func _preview_actor_base_side(side: String) -> String:
	return ScenePanelEditorPreviewScript.preview_base_side(_editor_preview_config(), side)


func _apply_actor_view(actor_value: Variant, actor_root: Control, actor_texture: TextureRect, placeholder: Label, silhouette: ColorRect, side: String) -> void:
	var base_side := _preview_actor_base_side(side)
	var base_position: Vector2 = _actor_base_positions.get(base_side, actor_root.position)
	var base_scale: Vector2 = _actor_base_scales.get(base_side, Vector2.ONE)
	ScenePanelActorRendererScript.apply_actor_view(
		actor_value,
		actor_root,
		actor_texture,
		placeholder,
		silhouette,
		side,
		base_position,
		base_scale,
		expression_position_offsets,
		portrait_position_offsets,
		expression_scale_overrides,
		portrait_scale_overrides,
		expression_texture_paths,
		portrait_texture_paths,
		default_left_actor_texture,
		default_center_actor_texture,
		default_right_actor_texture,
		flip_left_actor,
		flip_center_actor,
		flip_right_actor,
		actor_focus_scale,
		actor_dim_alpha,
		actor_silhouette_alpha,
		actor_hidden_alpha
	)


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


func _apply_dialogue_view(dialogue_value: Variant, scene_view: Dictionary) -> void:
	var display: Dictionary = ScenePanelRuntimeScript.dialogue_display(scene_view, dialogue_value, show_dialogue_meta, is_last_dialogue())
	dialogue_text.text = str(display.get("text", ""))
	speaker_side_label.text = str(display.get("meta_text", ""))
	speaker_side_label.visible = bool(display.get("meta_visible", false))
	continue_hint_label.text = str(display.get("continue_hint_text", ""))
	continue_hint_label.visible = bool(display.get("continue_hint_visible", false))
	_apply_nameplate_visibility(str(display.get("speaker", "")), str(display.get("speaker_side", "")))


func _build_dialogue_meta_text(scene_view: Dictionary, speaker_side: String, emphasis: String) -> String:
	return ScenePanelRuntimeScript.dialogue_meta_text(scene_view, speaker_side, emphasis)


func _apply_nameplate_visibility(speaker: String, speaker_side: String) -> void:
	if Engine.is_editor_hint():
		var labels: Dictionary = ScenePanelEditorPreviewScript.nameplate_labels(_editor_preview_config())
		left_nameplate_root.visible = true
		center_nameplate_root.visible = true
		right_nameplate_root.visible = true
		left_speaker_label.text = str(labels.get("left", "Left"))
		center_speaker_label.text = str(labels.get("center", "Center"))
		right_speaker_label.text = str(labels.get("right", "Right"))
		return
	var view: Dictionary = ScenePanelRuntimeScript.nameplate_visibility(speaker, speaker_side)
	left_nameplate_root.visible = bool(view.get("left_visible", false))
	center_nameplate_root.visible = bool(view.get("center_visible", false))
	right_nameplate_root.visible = bool(view.get("right_visible", false))
	var speaker_text: String = str(view.get("speaker_text", ""))
	left_speaker_label.text = speaker_text
	center_speaker_label.text = speaker_text
	right_speaker_label.text = speaker_text



func _configure_dialogue_click_area() -> void:
	left_speaker_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center_speaker_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right_speaker_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	speaker_side_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialogue_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	continue_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _editor_preview_config() -> Dictionary:
	return {
		"title": editor_preview_title,
		"speaker": editor_preview_speaker,
		"text": editor_preview_text,
		"speaker_side": editor_preview_speaker_side,
		"continue_hint": editor_preview_continue_hint,
		"use_shared_actor_slot": editor_preview_use_shared_actor_slot,
		"shared_actor_slot": editor_preview_shared_actor_slot,
		"show_calibration_stack": editor_preview_show_calibration_stack,
		"actors": {
			"left": {
				"enabled": editor_preview_left_actor_enabled,
				"display_name": editor_preview_left_actor_name,
				"portrait_id": editor_preview_left_actor_portrait_id,
				"expression_id": editor_preview_left_actor_expression_id,
				"visual_state": editor_preview_left_actor_visual_state,
			},
			"center": {
				"enabled": editor_preview_center_actor_enabled,
				"display_name": editor_preview_center_actor_name,
				"portrait_id": editor_preview_center_actor_portrait_id,
				"expression_id": editor_preview_center_actor_expression_id,
				"visual_state": editor_preview_center_actor_visual_state,
			},
			"right": {
				"enabled": editor_preview_right_actor_enabled,
				"display_name": editor_preview_right_actor_name,
				"portrait_id": editor_preview_right_actor_portrait_id,
				"expression_id": editor_preview_right_actor_expression_id,
				"visual_state": editor_preview_right_actor_visual_state,
			},
		},
	}


func _on_dialogue_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		continue_requested.emit()

