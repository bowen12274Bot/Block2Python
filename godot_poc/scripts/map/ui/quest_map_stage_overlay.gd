extends Control
class_name QuestMapStageOverlay

const UnlockBlockListRendererScript = preload("res://scripts/shared/unlock_block_list_renderer.gd")

signal close_requested()
signal story_requested()
signal demo_requested()
signal practice_requested()

@onready var stage_title_label: Label = get_node_or_null("Center/Panel/OverlayMargin/OverlayRoot/Header/TitleColumn/StageTitle")
@onready var stage_subtitle_label: Label = get_node_or_null("Center/Panel/OverlayMargin/OverlayRoot/Header/TitleColumn/StageSubtitle")
@onready var stage_description_label: Label = get_node_or_null("Center/Panel/OverlayMargin/OverlayRoot/StageDescription")
@onready var stage_action_note_label: Label = get_node_or_null("Center/Panel/OverlayMargin/OverlayRoot/ActionNote")
@onready var unlock_blocks_container: HFlowContainer = get_node_or_null("Center/Panel/OverlayMargin/OverlayRoot/UnlockBlocks")
@onready var stage_story_button: Button = get_node_or_null("Center/Panel/OverlayMargin/OverlayRoot/Buttons/StartStoryButton")
@onready var stage_demo_button: Button = get_node_or_null("Center/Panel/OverlayMargin/OverlayRoot/Buttons/StartDemoButton")
@onready var stage_practice_button: Button = get_node_or_null("Center/Panel/OverlayMargin/OverlayRoot/Buttons/StartPracticeButton")
@onready var stage_close_button: Button = get_node_or_null("Center/Panel/OverlayMargin/OverlayRoot/Header/CloseNudge/CloseButton")


func _ready() -> void:
	z_index = 100
	visible = false
	if stage_close_button != null:
		stage_close_button.pressed.connect(func() -> void:
			close_requested.emit()
		)
	if stage_story_button != null:
		stage_story_button.pressed.connect(func() -> void:
			story_requested.emit()
		)
	if stage_demo_button != null:
		stage_demo_button.pressed.connect(func() -> void:
			demo_requested.emit()
		)
	if stage_practice_button != null:
		stage_practice_button.pressed.connect(func() -> void:
			practice_requested.emit()
		)


func show_overlay(overlay_view: Dictionary) -> void:
	if stage_title_label != null:
		stage_title_label.text = str(overlay_view.get("title", "Stage"))
	if stage_subtitle_label != null:
		stage_subtitle_label.text = str(overlay_view.get("subtitle", "Demo + Practice"))
	if stage_description_label != null:
		stage_description_label.text = str(overlay_view.get("description", "No description available yet."))
	_apply_unlock_blocks(overlay_view)
	_apply_actions(overlay_view)
	visible = true


func hide_overlay() -> void:
	visible = false


func _apply_unlock_blocks(overlay_view: Dictionary) -> void:
	UnlockBlockListRendererScript.render(
		unlock_blocks_container,
		overlay_view.get("unlock_blocks", []),
		{
			"empty_text": "No new blocks yet.",
			"card_minimum_size": Vector2(160, 92),
			"margin_left": 10,
			"margin_top": 10,
			"margin_right": 10,
			"margin_bottom": 10,
			"column_separation": 6,
			"title_font_size": 18,
			"body_font_size": 14,
		}
	)


func _apply_actions(overlay_view: Dictionary) -> void:
	if stage_story_button != null:
		stage_story_button.disabled = bool(overlay_view.get("story_button_disabled", true))
		stage_story_button.text = str(overlay_view.get("story_button_text", "Start Story"))
	if stage_demo_button != null:
		stage_demo_button.disabled = bool(overlay_view.get("demo_button_disabled", true))
		stage_demo_button.text = str(overlay_view.get("demo_button_text", "Start Demo"))
	if stage_practice_button != null:
		stage_practice_button.disabled = bool(overlay_view.get("practice_button_disabled", true))
		stage_practice_button.text = str(overlay_view.get("practice_button_text", "Practice"))
	if stage_action_note_label != null:
		stage_action_note_label.text = str(overlay_view.get("action_note", ""))
