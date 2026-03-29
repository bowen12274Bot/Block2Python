extends RefCounted
class_name QuestMapGroupFlowRules


static func story_step(group_view: Dictionary) -> Dictionary:
	return _dict(group_view.get("story_step", {}))


static func demo_slot(group_view: Dictionary) -> Dictionary:
	return _dict(group_view.get("demo_slot", {}))


static func practice_slot(group_view: Dictionary) -> Dictionary:
	return _dict(group_view.get("practice_slot", {}))


static func is_story_available(group_view: Dictionary) -> bool:
	return not story_step(group_view).is_empty()


static func is_demo_unlocked(group_view: Dictionary) -> bool:
	return bool(demo_slot(group_view).get("is_unlocked", false))


static func is_practice_unlocked(group_view: Dictionary) -> bool:
	return bool(practice_slot(group_view).get("is_unlocked", false))


static func story_button_text(group_view: Dictionary) -> String:
	var step: Dictionary = story_step(group_view)
	return "Replay Story" if str(step.get("status_key", "")) == "completed" else "Start Story"


static func demo_button_text(group_view: Dictionary) -> String:
	return "Replay Demo" if bool(demo_slot(group_view).get("viewed", false)) else "Start Demo"


static func practice_button_text(group_view: Dictionary) -> String:
	var slot: Dictionary = practice_slot(group_view)
	var completed_count: int = int(slot.get("completed_count", 0))
	var total_count: int = int(slot.get("total_count", 0))
	return "Practice %d / %d" % [completed_count, max(total_count, 5)]


static func action_note_text(group_view: Dictionary) -> String:
	var practice_unlocked: bool = is_practice_unlocked(group_view)
	var demo_unlocked: bool = is_demo_unlocked(group_view)
	if practice_unlocked:
		return "Story opens the scene route, Demo unlocks after Story is completed, and Practice opens the current practice entry level."
	if demo_unlocked:
		return "Demo is now unlocked. Finish Demo once to unlock Practice."
	return "Complete Story first to unlock Demo. Practice remains locked until Demo is started."


static func _dict(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value
	return {}

