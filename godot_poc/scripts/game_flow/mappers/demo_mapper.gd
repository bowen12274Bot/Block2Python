extends RefCounted
class_name GameFlowDemoMapper

const QuestMapGroupCatalogScript = preload("res://scripts/map/catalog/quest_map_group_catalog.gd")


static func build_demo_view(state: Dictionary) -> Dictionary:
	var default_title: String = "Demo Placeholder"
	var default_body: String = "This demo flow is not defined yet."
	var demo_view: Dictionary = {
		"demo_id": "",
		"title": default_title,
		"group_id": "",
		"level_id": "",
		"prompt": "",
		"learning_markdown": "",
		"story_intro_markdown": "",
		"story_outro_markdown": "",
		"can_advance": false,
		"body": default_body,
		"current_level_id": "",
		"unlock_blocks": [],
	}

	var demo: Variant = state.get("demo", null)
	if demo is Dictionary:
		demo_view["demo_id"] = str(demo.get("demo_id", ""))
		demo_view["title"] = str(demo.get("title", default_title))
		demo_view["group_id"] = str(demo.get("group_id", ""))
		demo_view["level_id"] = str(demo.get("level_id", demo.get("current_level_id", "")))
		demo_view["prompt"] = str(demo.get("prompt", ""))
		demo_view["learning_markdown"] = str(demo.get("learning_markdown", ""))
		demo_view["story_intro_markdown"] = str(demo.get("story_intro_markdown", ""))
		demo_view["story_outro_markdown"] = str(demo.get("story_outro_markdown", ""))
		demo_view["can_advance"] = bool(demo.get("can_advance", false))
		demo_view["body"] = str(demo.get("body", default_body))
		demo_view["current_level_id"] = str(demo.get("current_level_id", demo_view["level_id"]))
		demo_view["unlock_blocks"] = normalize_unlock_blocks(demo.get("unlock_blocks", QuestMapGroupCatalogScript.unlock_blocks_for_group(str(demo_view.get("group_id", "")))))

	return demo_view


static func normalize_unlock_blocks(value: Variant) -> Array[Dictionary]:
	var blocks: Array[Dictionary] = []
	if value is Array:
		for block_variant in value:
			if block_variant is Dictionary:
				blocks.append(block_variant)
	return blocks
