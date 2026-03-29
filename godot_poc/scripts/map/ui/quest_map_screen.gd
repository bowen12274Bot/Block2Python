extends Control

const QuestMapGroupCardBindingScript = preload("res://scripts/map/ui/quest_map_group_card_binding.gd")
const QuestMapGroupCardRendererScript = preload("res://scripts/map/ui/quest_map_group_card_renderer.gd")
const QuestMapOverlayPresenterScript = preload("res://scripts/map/presentation/quest_map_overlay_presenter.gd")
const QuestMapGroupNotePresenterScript = preload("res://scripts/map/presentation/quest_map_group_note_presenter.gd")
const QuestMapGroupFlowRulesScript = preload("res://scripts/map/presentation/quest_map_group_flow_rules.gd")

signal start_bridge_requested()
signal reset_requested()
signal advance_requested()
signal node_open_requested()
signal debug_toggled(visible: bool)
signal stage_story_requested(group_id: String)
signal stage_demo_requested(group_id: String)
signal stage_practice_requested(group_id: String)

@onready var start_bridge_button: Button = get_node_or_null("HudMargin/HudRoot/TopBar/ActionRow/StartBridgeButton")
@onready var reset_button: Button = get_node_or_null("HudMargin/HudRoot/TopBar/ActionRow/ResetButton")
@onready var advance_button: Button = get_node_or_null("HudMargin/HudRoot/TopBar/ActionRow/AdvanceButton")
@onready var open_node_button: Button = get_node_or_null("HudMargin/HudRoot/TopBar/ActionRow/OpenNodeButton")
@onready var debug_toggle_button: Button = get_node_or_null("HudMargin/HudRoot/TopBar/ActionRow/DebugToggleButton")
@onready var status_label: Label = get_node_or_null("HudMargin/HudRoot/StatusLabel")
@onready var quest_map_stage: QuestMapStage = get_node_or_null("StageFrame")
@onready var stage_overlay: QuestMapStageOverlay = get_node_or_null("StageOverlay")

var _last_map_view: Dictionary = {}
var _group_lookup: Dictionary = {}
var _selected_group_id: String = ""
var _group_cards: Dictionary = {}


func _ready() -> void:
	_group_cards = QuestMapGroupCardBindingScript.collect(self, Callable(self, "_on_group_pressed"))

	if start_bridge_button != null:
		start_bridge_button.pressed.connect(func() -> void:
			start_bridge_requested.emit()
		)
	if reset_button != null:
		reset_button.pressed.connect(func() -> void:
			reset_requested.emit()
		)
	if advance_button != null:
		advance_button.pressed.connect(func() -> void:
			advance_requested.emit()
		)
		advance_button.disabled = true
	if open_node_button != null:
		open_node_button.pressed.connect(func() -> void:
			node_open_requested.emit()
		)
		open_node_button.disabled = true
	if debug_toggle_button != null:
		debug_toggle_button.toggled.connect(func(button_pressed: bool) -> void:
			debug_toggled.emit(button_pressed)
		)
	if stage_overlay != null:
		stage_overlay.close_requested.connect(hide_stage_overlay)
		stage_overlay.story_requested.connect(_on_stage_story_pressed)
		stage_overlay.demo_requested.connect(_on_stage_demo_pressed)
		stage_overlay.practice_requested.connect(_on_stage_practice_pressed)


func show_map(map_view: Dictionary) -> void:
	_last_map_view = map_view.duplicate(true)
	_group_lookup = _index_groups(_last_map_view)
	if quest_map_stage != null:
		quest_map_stage.show_map(map_view)
	_render_group_cards(map_view)
	if stage_overlay != null and stage_overlay.visible and _selected_group_id != "":
		var refreshed_group: Dictionary = _find_group_view(_selected_group_id)
		if refreshed_group.is_empty():
			hide_stage_overlay()
		else:
			_apply_stage_overlay(refreshed_group)


func set_status(text: String) -> void:
	if status_label != null:
		status_label.text = text


func set_note(text: String) -> void:
	if quest_map_stage != null:
		quest_map_stage.set_helper_text(text)


func set_bridge_running(is_running: bool) -> void:
	if start_bridge_button != null:
		start_bridge_button.disabled = is_running
	if reset_button != null:
		reset_button.disabled = not is_running
	if advance_button != null:
		advance_button.disabled = true
	if open_node_button != null:
		open_node_button.disabled = true


func set_current_node_enterable(is_enterable: bool) -> void:
	if open_node_button != null:
		open_node_button.disabled = not is_enterable


func set_can_advance(can_advance: bool) -> void:
	if advance_button != null:
		advance_button.disabled = not can_advance


func set_debug_visible(debug_visible: bool) -> void:
	if debug_toggle_button != null:
		debug_toggle_button.button_pressed = debug_visible
		debug_toggle_button.text = "Hide Debug" if debug_visible else "Show Debug"


func show_stage_overlay(group_view: Dictionary) -> void:
	_selected_group_id = str(group_view.get("group_id", ""))
	_apply_stage_overlay(group_view)


func hide_stage_overlay() -> void:
	if stage_overlay != null:
		stage_overlay.hide_overlay()
	_selected_group_id = ""


func _render_group_cards(map_view: Dictionary) -> void:
	for card_view in _group_cards.values():
		QuestMapGroupCardRendererScript.apply_group_card(card_view, {})

	var groups_variant: Variant = map_view.get("groups", [])
	if not (groups_variant is Array):
		return

	for group_variant in groups_variant:
		if not (group_variant is Dictionary):
			continue
		var group_view: Dictionary = group_variant
		var group_id: String = str(group_view.get("group_id", ""))
		if _group_cards.has(group_id):
			QuestMapGroupCardRendererScript.apply_group_card(_group_cards[group_id], group_view)


func _on_group_pressed(group_id: String) -> void:
	var group_view: Dictionary = _find_group_view(group_id)
	if group_view.is_empty():
		set_note("Selected level group: %s" % group_id)
		return

	if not bool(group_view.get("is_enterable", false)):
		set_note("This group is still locked.")
		return

	set_note(QuestMapGroupNotePresenterScript.build_group_selection_note(group_view))
	show_stage_overlay(group_view)


func _on_stage_story_pressed() -> void:
	if _selected_group_id == "":
		return
	var group_id: String = _selected_group_id
	hide_stage_overlay()
	stage_story_requested.emit(group_id)


func _on_stage_demo_pressed() -> void:
	if _selected_group_id == "":
		return
	var group_id: String = _selected_group_id
	hide_stage_overlay()
	stage_demo_requested.emit(group_id)


func _on_stage_practice_pressed() -> void:
	if _selected_group_id == "":
		return
	var refreshed_group: Dictionary = _find_group_view(_selected_group_id)
	if refreshed_group.is_empty() or not QuestMapGroupFlowRulesScript.is_practice_unlocked(refreshed_group):
		return
	var group_id: String = _selected_group_id
	hide_stage_overlay()
	stage_practice_requested.emit(group_id)


func _apply_stage_overlay(group_view: Dictionary) -> void:
	var overlay_view: Dictionary = QuestMapOverlayPresenterScript.build_overlay_view(group_view)
	if stage_overlay != null:
		stage_overlay.show_overlay(overlay_view)


func _find_group_view(group_id: String) -> Dictionary:
	var group_view_variant: Variant = _group_lookup.get(group_id, {})
	if group_view_variant is Dictionary:
		return group_view_variant
	return {}


func _index_groups(map_view: Dictionary) -> Dictionary:
	var lookup: Dictionary = {}
	var groups_variant: Variant = map_view.get("groups", [])
	if groups_variant is Array:
		for group_view_variant in groups_variant:
			if group_view_variant is Dictionary:
				var group_view: Dictionary = group_view_variant
				lookup[str(group_view.get("group_id", ""))] = group_view
	return lookup


