extends RefCounted
class_name QuestMapGroupCatalog

const GROUP_ART_DIRECTORY := "res://art/map/stages"
const GROUPS := {
	"group-01": {
		"display_title": "Input Gate",
		"theme_description": "Start with input and output basics, then unlock a guided five-level practice chain.",
		"art_file": "floating_islands1.png",
		"scene_group_name": "Group01Card",
		"scene_nameplate_name": "Group01Nameplate",
		"unlock_blocks": [
			{"title": "print", "description": "Output text to the screen."},
			{"title": "input", "description": "Read user input into your program."},
		],
	},
	"group-02": {
		"display_title": "Variable Base",
		"theme_description": "Build a base camp around variables and storing values before the next branch opens.",
		"art_file": "floating_islands2.png",
		"scene_group_name": "Group02Card",
		"scene_nameplate_name": "Group02Nameplate",
		"unlock_blocks": [
			{"title": "variable", "description": "Store a value and reuse it later in the program."},
			{"title": "assignment", "description": "Update a named value as the program continues."},
		],
	},
	"group-03": {
		"display_title": "If Canyon",
		"theme_description": "Cross the canyon by learning condition checks and branching decisions.",
		"art_file": "floating_islands3.png",
		"scene_group_name": "Group03Card",
		"scene_nameplate_name": "Group03Nameplate",
		"unlock_blocks": [
			{"title": "if", "description": "Run code only when a condition is true."},
			{"title": "compare", "description": "Check values before choosing a branch."},
		],
	},
	"group-04": {
		"display_title": "Loop Lab",
		"theme_description": "Enter the loop lab and repeat patterns until the route becomes second nature.",
		"art_file": "floating_islands4.png",
		"scene_group_name": "Group04Card",
		"scene_nameplate_name": "Group04Nameplate",
		"unlock_blocks": [
			{"title": "loop", "description": "Repeat a block of work with the same structure."},
			{"title": "range", "description": "Control how many times a loop should run."},
		],
	},
	"group-05": {
		"display_title": "Bug King Castle",
		"theme_description": "Climb through the final castle route and prepare for the full five-stage handoff.",
		"art_file": "Final_Castle1.png",
		"scene_group_name": "Group05Card",
		"scene_nameplate_name": "Group05Nameplate",
		"unlock_blocks": [
			{"title": "debug", "description": "Trace the final route and inspect how the logic behaves."},
			{"title": "boss review", "description": "Combine the earlier concepts in one longer stage."},
		],
	},
}

const DEFAULT_UNLOCK_BLOCKS := [
	{"title": "Coming Soon", "description": "Future stages will add more blocks here."},
]


static func group_ids() -> Array[String]:
	var ids: Array[String] = []
	for group_id in GROUPS.keys():
		ids.append(str(group_id))
	ids.sort()
	return ids


static func display_title_for_group(group_id: String, fallback_title: String) -> String:
	return str(_group_data(group_id).get("display_title", fallback_title))


static func theme_title_for_group(group_id: String, fallback_title: String) -> String:
	return display_title_for_group(group_id, fallback_title)


static func theme_description_for_group(group_id: String) -> String:
	return str(_group_data(group_id).get("theme_description", "This stage will unlock new blocks and guided practice in a later update."))


static func unlock_blocks_for_group(group_id: String) -> Array[Dictionary]:
	var raw_blocks: Variant = _group_data(group_id).get("unlock_blocks", DEFAULT_UNLOCK_BLOCKS)
	var results: Array[Dictionary] = []
	if raw_blocks is Array:
		for block_variant in raw_blocks:
			if block_variant is Dictionary:
				results.append(block_variant)
	return results


static func art_path_for_group(group_id: String) -> String:
	if group_id == "":
		return ""
	var file_name: String = str(_group_data(group_id).get("art_file", "%s.png" % group_id))
	return "%s/%s" % [GROUP_ART_DIRECTORY, file_name]


static func scene_group_name(group_id: String) -> String:
	return str(_group_data(group_id).get("scene_group_name", group_id))


static func scene_nameplate_name(group_id: String) -> String:
	return str(_group_data(group_id).get("scene_nameplate_name", group_id))


static func _group_data(group_id: String) -> Dictionary:
	var raw_group: Variant = GROUPS.get(group_id, {})
	if raw_group is Dictionary:
		return raw_group
	return {}
