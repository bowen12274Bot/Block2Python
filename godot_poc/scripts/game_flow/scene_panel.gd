extends PanelContainer
class_name ScenePanel

signal continue_requested()

const FOCUS_LEFT_COLOR := Color(0.58, 0.92, 1.0, 0.38)
const FOCUS_RIGHT_COLOR := Color(0.76, 0.76, 1.0, 0.34)
const DIM_COLOR := Color(0.35, 0.39, 0.52, 0.18)
const HIDDEN_COLOR := Color(0.16, 0.18, 0.24, 0.08)
const SILHOUETTE_COLOR := Color(0.07, 0.08, 0.12, 0.68)

@onready var title_label: Label = $LayoutMargin/SceneRoot/TopBar/SceneTitle
@onready var index_label: Label = $LayoutMargin/SceneRoot/TopBar/IndexLabel
@onready var left_visual: ColorRect = $LayoutMargin/SceneRoot/Stage/CharacterRow/LeftActorSlot/LeftActorVisual
@onready var left_name_label: Label = $LayoutMargin/SceneRoot/Stage/CharacterRow/LeftActorSlot/LeftActorName
@onready var left_state_label: Label = $LayoutMargin/SceneRoot/Stage/CharacterRow/LeftActorSlot/LeftActorState
@onready var right_visual: ColorRect = $LayoutMargin/SceneRoot/Stage/CharacterRow/RightActorSlot/RightActorVisual
@onready var right_name_label: Label = $LayoutMargin/SceneRoot/Stage/CharacterRow/RightActorSlot/RightActorName
@onready var right_state_label: Label = $LayoutMargin/SceneRoot/Stage/CharacterRow/RightActorSlot/RightActorState
@onready var speaker_label: Label = $LayoutMargin/SceneRoot/DialogueLayer/Nameplate/NameplateMargin/SpeakerLabel
@onready var dialogue_panel: PanelContainer = $LayoutMargin/SceneRoot/DialogueLayer/DialoguePanel
@onready var speaker_side_label: Label = $LayoutMargin/SceneRoot/DialogueLayer/DialoguePanel/DialogueMargin/DialogueRoot/DialogueMeta/SpeakerSideLabel
@onready var dialogue_text: RichTextLabel = $LayoutMargin/SceneRoot/DialogueLayer/DialoguePanel/DialogueMargin/DialogueRoot/DialogueText
@onready var continue_hint_label: Label = $LayoutMargin/SceneRoot/DialogueLayer/DialoguePanel/DialogueMargin/DialogueRoot/DialogueMeta/ContinueHintLabel
@onready var status_overlay: Label = $LayoutMargin/SceneRoot/DialogueLayer/DialoguePanel/DialogueMargin/DialogueRoot/StatusOverlay

var _scene_view: Dictionary = {}
var _dialogue_blocks: Array[Dictionary] = []
var _current_index: int = 0


func _ready() -> void:
	_configure_dialogue_click_area()
	dialogue_panel.gui_input.connect(_on_dialogue_panel_gui_input)


func show_scene(scene_view: Dictionary) -> void:
	_scene_view = scene_view.duplicate(true)
	_dialogue_blocks = _dialogue_array_from_view(_scene_view)
	_current_index = clampi(int(_scene_view.get("current_index", 0)), 0, max(_dialogue_blocks.size() - 1, 0))
	_render_current_dialogue()


func show_placeholder(message: String) -> void:
	show_scene({
		"title": "Scene",
		"dialogue": {
			"speaker": "Narrator",
			"text": message,
			"speaker_side": "",
			"emphasis": "normal",
		},
		"continue_hint_text": "Click to continue",
	})


func set_status_overlay(text: String) -> void:
	status_overlay.visible = text != ""
	status_overlay.text = text


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


func _render_current_dialogue() -> void:
	title_label.text = str(_scene_view.get("title", "Scene"))
	index_label.text = _build_index_label()
	var current_dialogue: Dictionary = {}
	if not _dialogue_blocks.is_empty():
		current_dialogue = _dialogue_blocks[_current_index]
	var left_actor: Dictionary = _actor_view_for_side("left", current_dialogue)
	var right_actor: Dictionary = _actor_view_for_side("right", current_dialogue)
	_apply_actor_view(left_actor, left_visual, left_name_label, left_state_label, "Left")
	_apply_actor_view(right_actor, right_visual, right_name_label, right_state_label, "Right")
	_apply_dialogue_view(current_dialogue, _current_scene_view(current_dialogue))


func _build_index_label() -> String:
	var total_blocks: int = _dialogue_blocks.size()
	if total_blocks <= 0:
		return ""
	return "%d / %d" % [_current_index + 1, total_blocks]


func _apply_actor_view(actor_value: Variant, visual_target: ColorRect, name_target: Label, state_target: Label, side_label: String) -> void:
	var actor: Dictionary = actor_value if actor_value is Dictionary else {}
	var display_name: String = str(actor.get("display_name", ""))
	var actor_id: String = str(actor.get("actor_id", ""))
	var pose_id: String = str(actor.get("pose_id", "default"))
	var expression_id: String = str(actor.get("expression_id", ""))
	var visual_state: String = str(actor.get("visual_state", "hidden"))

	if display_name == "":
		display_name = actor_id
	if display_name == "":
		display_name = side_label

	name_target.text = display_name
	state_target.text = _build_actor_state_text(visual_state, pose_id, expression_id)
	visual_target.color = _actor_color(visual_state, side_label)
	visual_target.visible = visual_state != "hidden"
	name_target.visible = visual_state != "hidden"
	state_target.visible = visual_state != "hidden"


func _build_actor_state_text(visual_state: String, pose_id: String, expression_id: String) -> String:
	var parts: Array[String] = [visual_state]
	if pose_id != "" and pose_id != "default":
		parts.append(pose_id)
	if expression_id != "":
		parts.append(expression_id)
	return " | ".join(parts)


func _actor_color(visual_state: String, side_label: String) -> Color:
	match visual_state:
		"focus":
			return FOCUS_LEFT_COLOR if side_label == "Left" else FOCUS_RIGHT_COLOR
		"dim":
			return DIM_COLOR
		"silhouette":
			return SILHOUETTE_COLOR
		"hidden":
			return HIDDEN_COLOR
		_:
			return DIM_COLOR


func _apply_dialogue_view(dialogue_value: Variant, scene_view: Dictionary) -> void:
	var dialogue: Dictionary = dialogue_value if dialogue_value is Dictionary else {}
	var speaker: String = str(dialogue.get("speaker", "Narrator"))
	var text: String = str(dialogue.get("text", "No dialogue available."))
	var speaker_side: String = str(dialogue.get("speaker_side", ""))
	var emphasis: String = str(dialogue.get("emphasis", "normal"))

	speaker_label.text = speaker
	dialogue_text.text = text
	speaker_side_label.text = _build_dialogue_meta_text(scene_view, speaker_side, emphasis)
	continue_hint_label.text = _continue_hint_text(scene_view)


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
	if parts.is_empty():
		return "Story presentation placeholder"
	return " | ".join(parts)


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
	current_view["right_actor"] = _actor_view_for_side("right", dialogue)
	current_view["background"] = {
		"background_id": str(dialogue.get("background_id", "")),
	}
	return current_view


func _continue_hint_text(scene_view: Dictionary) -> String:
	if is_last_dialogue():
		return "Continue"
	return str(scene_view.get("continue_hint_text", "Click to continue"))


func _configure_dialogue_click_area() -> void:
	speaker_side_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialogue_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	continue_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _on_dialogue_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		continue_requested.emit()
