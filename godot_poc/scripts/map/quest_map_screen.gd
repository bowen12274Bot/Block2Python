extends Control

const QuestMapSelectionPresenterScript = preload("res://scripts/map/quest_map_selection_presenter.gd")
const GROUP_ART_DIRECTORY := "res://art/map/stages"
const GROUP_ART_FILES := {
	"group-01": "floating_islands1.png",
	"group-02": "floating_islands2.png",
	"group-03": "floating_islands3.png",
	"group-04": "floating_islands4.png",
	"group-05": "Final_Castle1.png",
}
const GROUP_DISPLAY_TITLES := {
	"group-01": "Input Gate",
	"group-02": "Variable Base",
	"group-03": "If Canyon",
	"group-04": "Loop Lab",
	"group-05": "Bug King Castle",
}

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
@onready var stage_overlay: Control = get_node_or_null("StageOverlay")
@onready var stage_title_label: Label = get_node_or_null("StageOverlay/Center/Panel/OverlayMargin/OverlayRoot/Header/TitleColumn/StageTitle")
@onready var stage_subtitle_label: Label = get_node_or_null("StageOverlay/Center/Panel/OverlayMargin/OverlayRoot/Header/TitleColumn/StageSubtitle")
@onready var stage_description_label: Label = get_node_or_null("StageOverlay/Center/Panel/OverlayMargin/OverlayRoot/StageDescription")
@onready var stage_action_note_label: Label = get_node_or_null("StageOverlay/Center/Panel/OverlayMargin/OverlayRoot/ActionNote")
@onready var unlock_blocks_container: HFlowContainer = get_node_or_null("StageOverlay/Center/Panel/OverlayMargin/OverlayRoot/UnlockBlocks")
@onready var stage_story_button: Button = get_node_or_null("StageOverlay/Center/Panel/OverlayMargin/OverlayRoot/Buttons/StartStoryButton")
@onready var stage_demo_button: Button = get_node_or_null("StageOverlay/Center/Panel/OverlayMargin/OverlayRoot/Buttons/StartDemoButton")
@onready var stage_practice_button: Button = get_node_or_null("StageOverlay/Center/Panel/OverlayMargin/OverlayRoot/Buttons/StartPracticeButton")
@onready var stage_close_button: Button = get_node_or_null("StageOverlay/Center/Panel/OverlayMargin/OverlayRoot/Header/CloseButton")

var _last_map_view: Dictionary = {}
var _selected_group_id: String = ""
var _overlay_group_view: Dictionary = {}
var _group_cards: Dictionary = {}


func _ready() -> void:
	_collect_group_cards()

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
	if stage_close_button != null:
		stage_close_button.pressed.connect(hide_stage_overlay)
	if stage_story_button != null:
		stage_story_button.pressed.connect(_on_stage_story_pressed)
	if stage_demo_button != null:
		stage_demo_button.pressed.connect(_on_stage_demo_pressed)
	if stage_practice_button != null:
		stage_practice_button.pressed.connect(_on_stage_practice_pressed)
	if stage_overlay != null:
		stage_overlay.z_index = 100
		stage_overlay.visible = false




func show_map(map_view: Dictionary) -> void:
	_last_map_view = map_view.duplicate(true)
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
	if stage_overlay != null:
		stage_overlay.visible = true


func hide_stage_overlay() -> void:
	if stage_overlay != null:
		stage_overlay.visible = false
	_overlay_group_view = {}
	_selected_group_id = ""


func _collect_group_cards() -> void:
	_group_cards.clear()
	for group_id in ["group-01", "group-02", "group-03", "group-04", "group-05"]:
		var base_name: String = _scene_group_name(group_id)
		var root: Button = get_node_or_null("StageFrame/HotspotLayer/%s" % base_name)
		if root == null:
			continue

		var bound_group_id: String = group_id
		root.mouse_filter = Control.MOUSE_FILTER_STOP
		root.focus_mode = Control.FOCUS_NONE
		root.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		root.pressed.connect(func() -> void:
			_on_group_pressed(bound_group_id)
		)

		var lock_icon: TextureRect = get_node_or_null("StageFrame/HotspotLayer/%s/LockIcon" % base_name)
		var art_rect: TextureRect = get_node_or_null("StageFrame/HotspotLayer/%s/Art" % base_name)
		var art_placeholder: Label = get_node_or_null("StageFrame/HotspotLayer/%s/ArtPlaceholder" % base_name)
		var nameplate: Node = get_node_or_null("StageFrame/NameplateLayer/%s" % _scene_nameplate_name(group_id))

		for node in [lock_icon, art_rect, art_placeholder, nameplate]:
			if node != null:
				node.mouse_filter = Control.MOUSE_FILTER_IGNORE

		_group_cards[group_id] = {
			"group_id": group_id,
			"root": root,
			"lock_icon": lock_icon,
			"art": art_rect,
			"art_placeholder": art_placeholder,
			"nameplate": nameplate,
		}


func _render_group_cards(map_view: Dictionary) -> void:
	for card_view in _group_cards.values():
		_apply_group_card(card_view, {})

	var groups_variant: Variant = map_view.get("groups", [])
	if not (groups_variant is Array):
		return

	for group_variant in groups_variant:
		if not (group_variant is Dictionary):
			continue
		var group_view: Dictionary = group_variant
		var group_id: String = str(group_view.get("group_id", ""))
		if _group_cards.has(group_id):
			_apply_group_card(_group_cards[group_id], group_view)


func _apply_group_card(card_view: Dictionary, group_view: Dictionary) -> void:
	var root: Button = card_view.get("root", null)
	if root == null:
		return
	var card_group_id: String = str(card_view.get("group_id", ""))
	var lock_icon: TextureRect = card_view.get("lock_icon", null)
	var art_rect: TextureRect = card_view.get("art", null)
	var art_placeholder: Label = card_view.get("art_placeholder", null)
	var nameplate: Node = card_view.get("nameplate", null)

	if group_view.is_empty():
		root.visible = false
		if nameplate != null:
			nameplate.visible = false
		return

	root.visible = true
	if nameplate != null:
		nameplate.visible = true
	var group_id: String = str(group_view.get("group_id", card_group_id))
	var group_art: Texture2D = _load_group_art(group_id)
	if art_rect != null:
		art_rect.texture = group_art
		art_rect.modulate = Color(1, 1, 1, 1) if bool(group_view.get("is_enterable", false)) else Color(0.72, 0.72, 0.72, 0.92)
	if art_placeholder != null:
		art_placeholder.visible = group_art == null
		art_placeholder.text = "Drop art\n%s/%s.png" % [GROUP_ART_DIRECTORY, group_id]
	var fallback_title: String = str(group_view.get("theme_title", group_view.get("title", "Stage")))
	var stage_title: String = _display_title_for_group(group_id, fallback_title)
	if nameplate != null:
		if nameplate.has_method("set_stage_number_text"):
			nameplate.call("set_stage_number_text", _stage_number_text(group_id))
		if nameplate.has_method("set_stage_title_text"):
			nameplate.call("set_stage_title_text", stage_title)
	if lock_icon != null:
		lock_icon.visible = str(group_view.get("status_key", "locked")) == "locked"
	root.add_theme_stylebox_override("normal", _card_style())
	root.add_theme_stylebox_override("hover", _card_hover_style())
	root.add_theme_stylebox_override("pressed", _card_hover_style())
	root.add_theme_stylebox_override("focus", _card_hover_style())
	root.add_theme_stylebox_override("disabled", _card_style())


func _load_group_art(group_id: String) -> Texture2D:
	if group_id == "":
		return null
	var file_name: String = str(GROUP_ART_FILES.get(group_id, "%s.png" % group_id))
	var path := "%s/%s" % [GROUP_ART_DIRECTORY, file_name]
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


func _stage_number_text(group_id: String) -> String:
	var parts := group_id.split("-")
	if parts.size() < 2:
		return group_id
	return parts[1]

func _display_title_for_group(group_id: String, fallback_title: String) -> String:
	return str(GROUP_DISPLAY_TITLES.get(group_id, fallback_title))


func _on_group_pressed(group_id: String) -> void:
	var group_view: Dictionary = _find_group_view(group_id)
	if group_view.is_empty():
		set_note("Selected level group: %s" % group_id)
		return

	if not bool(group_view.get("is_enterable", false)):
		set_note("This group is still locked.")
		return

	set_note(QuestMapSelectionPresenterScript.build_group_selection_note(group_view))
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
	if stage_practice_button != null and stage_practice_button.disabled:
		return
	var group_id: String = _selected_group_id
	hide_stage_overlay()
	stage_practice_requested.emit(group_id)


func _apply_stage_overlay(group_view: Dictionary) -> void:
	_overlay_group_view = group_view.duplicate(true)
	if stage_title_label != null:
		stage_title_label.text = str(group_view.get("theme_title", group_view.get("title", "Stage")))
	if stage_subtitle_label != null:
		stage_subtitle_label.text = str(group_view.get("subtitle", "Demo + Practice"))
	if stage_description_label != null:
		stage_description_label.text = str(group_view.get("theme_description", "No description available yet."))
	_populate_unlock_blocks(group_view)
	_refresh_overlay_actions(group_view)


func _populate_unlock_blocks(group_view: Dictionary) -> void:
	if unlock_blocks_container == null:
		return
	for child in unlock_blocks_container.get_children():
		child.queue_free()

	var unlock_blocks_variant: Variant = group_view.get("unlock_blocks", [])
	if not (unlock_blocks_variant is Array) or unlock_blocks_variant.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No new blocks yet."
		unlock_blocks_container.add_child(empty_label)
		return

	for block_variant in unlock_blocks_variant:
		if not (block_variant is Dictionary):
			continue
		var block_view: Dictionary = block_variant
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(160, 92)
		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 10)
		margin.add_theme_constant_override("margin_top", 10)
		margin.add_theme_constant_override("margin_right", 10)
		margin.add_theme_constant_override("margin_bottom", 10)
		card.add_child(margin)
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 6)
		margin.add_child(column)
		var title_label := Label.new()
		title_label.text = str(block_view.get("title", "Block"))
		title_label.add_theme_font_size_override("font_size", 18)
		column.add_child(title_label)
		var body_label := Label.new()
		body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body_label.text = str(block_view.get("description", ""))
		column.add_child(body_label)
		unlock_blocks_container.add_child(card)


func _refresh_overlay_actions(group_view: Dictionary) -> void:
	var story_step_variant: Variant = group_view.get("story_step", {})
	var demo_slot_variant: Variant = group_view.get("demo_slot", {})
	var practice_slot_variant: Variant = group_view.get("practice_slot", {})
	var story_step: Dictionary = story_step_variant if story_step_variant is Dictionary else {}
	var demo_slot: Dictionary = demo_slot_variant if demo_slot_variant is Dictionary else {}
	var practice_slot: Dictionary = practice_slot_variant if practice_slot_variant is Dictionary else {}
	var practice_unlocked: bool = bool(practice_slot.get("is_unlocked", false))
	var practice_completed: int = int(practice_slot.get("completed_count", 0))
	var practice_total: int = int(practice_slot.get("total_count", 0))

	if stage_story_button != null:
		stage_story_button.disabled = story_step.is_empty()
		stage_story_button.text = "Replay Story" if str(story_step.get("status_key", "")) == "completed" else "Start Story"
	if stage_demo_button != null:
		var demo_unlocked: bool = bool(demo_slot.get("is_unlocked", false))
		stage_demo_button.disabled = not demo_unlocked
		stage_demo_button.text = "Start Demo" if not bool(demo_slot.get("viewed", false)) else "Replay Demo"
	if stage_practice_button != null:
		stage_practice_button.disabled = not practice_unlocked
		stage_practice_button.text = "Practice %d / %d" % [practice_completed, max(practice_total, 5)]
	if stage_action_note_label != null:
		var demo_unlocked: bool = bool(demo_slot.get("is_unlocked", false))
		if practice_unlocked:
			stage_action_note_label.text = "Story opens the scene route, Demo unlocks after Story is completed, and Practice opens the current practice entry level."
		elif demo_unlocked:
			stage_action_note_label.text = "Demo is now unlocked. Finish Demo once to unlock Practice."
		else:
			stage_action_note_label.text = "Complete Story first to unlock Demo. Practice remains locked until Demo is started."


func _find_group_view(group_id: String) -> Dictionary:
	var groups: Variant = _last_map_view.get("groups", [])
	if groups is Array:
		for group_view_variant in groups:
			if not (group_view_variant is Dictionary):
				continue
			var group_view: Dictionary = group_view_variant
			if str(group_view.get("group_id", "")) == group_id:
				return group_view
	return {}


func _scene_group_name(group_id: String) -> String:
	match group_id:
		"group-01":
			return "Group01Card"
		"group-02":
			return "Group02Card"
		"group-03":
			return "Group03Card"
		"group-04":
			return "Group04Card"
		"group-05":
			return "Group05Card"
		_:
			return group_id

func _scene_nameplate_name(group_id: String) -> String:
	match group_id:
		"group-01":
			return "Group01Nameplate"
		"group-02":
			return "Group02Nameplate"
		"group-03":
			return "Group03Nameplate"
		"group-04":
			return "Group04Nameplate"
		"group-05":
			return "Group05Nameplate"
		_:
			return group_id


func _card_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.corner_radius_top_left = 24
	style.corner_radius_top_right = 24
	style.corner_radius_bottom_right = 24
	style.corner_radius_bottom_left = 24
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
	style.shadow_size = 6
	style.bg_color = Color(1, 1, 1, 0.02)
	style.border_color = Color(1, 1, 1, 0.30)
	return style


func _card_hover_style() -> StyleBoxFlat:
	var style := _card_style()
	style.bg_color = Color(1, 1, 1, 0.08)
	style.border_color = Color(1, 1, 1, 0.52)
	style.shadow_size = 10
	return style
