extends RefCounted
class_name QuestMapOverlayPresenter

const QuestMapGroupFlowRulesScript = preload("res://scripts/map/presentation/quest_map_group_flow_rules.gd")


static func build_overlay_view(group_view: Dictionary) -> Dictionary:
	return {
		"title": str(group_view.get("theme_title", group_view.get("title", "Stage"))),
		"subtitle": str(group_view.get("subtitle", "Demo + Practice")),
		"description": str(group_view.get("theme_description", "No description available yet.")),
		"unlock_blocks": _unlock_blocks(group_view),
		"story_button_disabled": not QuestMapGroupFlowRulesScript.is_story_available(group_view),
		"story_button_text": QuestMapGroupFlowRulesScript.story_button_text(group_view),
		"demo_button_disabled": not QuestMapGroupFlowRulesScript.is_demo_unlocked(group_view),
		"demo_button_text": QuestMapGroupFlowRulesScript.demo_button_text(group_view),
		"practice_button_disabled": not QuestMapGroupFlowRulesScript.is_practice_unlocked(group_view),
		"practice_button_text": QuestMapGroupFlowRulesScript.practice_button_text(group_view),
		"action_note": QuestMapGroupFlowRulesScript.action_note_text(group_view),
	}


static func _unlock_blocks(group_view: Dictionary) -> Array[Dictionary]:
	var unlock_blocks_variant: Variant = group_view.get("unlock_blocks", [])
	var results: Array[Dictionary] = []
	if unlock_blocks_variant is Array:
		for block_variant in unlock_blocks_variant:
			if block_variant is Dictionary:
				results.append(block_variant)
	return results



