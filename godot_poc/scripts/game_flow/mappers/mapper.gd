extends RefCounted
class_name GameFlowMapper

const GameFlowSceneMapperScript = preload("res://scripts/game_flow/mappers/scene_mapper.gd")
const GameFlowDemoMapperScript = preload("res://scripts/game_flow/mappers/demo_mapper.gd")
const GameFlowPracticeMapperScript = preload("res://scripts/game_flow/mappers/practice_mapper.gd")


static func map_game_state(state: Dictionary) -> Dictionary:
    var meta: Dictionary = {
        "mode": str(state.get("mode", "")),
        "quest_id": str(state.get("quest_id", "")),
        "node_id": str(state.get("node_id", "")),
        "node_title": str(state.get("node_title", "")),
    }

    var player_profile_view: Dictionary = _build_player_profile_view(state)
    var scene_view: Dictionary = GameFlowSceneMapperScript.build_scene_view(state, meta)
    var demo_view: Dictionary = GameFlowDemoMapperScript.build_demo_view(state)
    var practice_view: Dictionary = GameFlowPracticeMapperScript.build_practice_view(state)
    var action_view: Dictionary = GameFlowPracticeMapperScript.build_action_view(state)

    return {
        "meta": meta,
        "player_profile_view": player_profile_view,
        "scene_view": scene_view,
        "demo_view": demo_view,
        "practice_view": practice_view,
        "action_view": action_view,
    }


static func _build_player_profile_view(state: Dictionary) -> Dictionary:
    var profile: Variant = state.get("player_profile", {})
    var name: String = ""
    var gender: String = ""
    var profile_created: bool = false
    if profile is Dictionary:
        name = str(profile.get("name", ""))
        gender = str(profile.get("gender", ""))
        profile_created = bool(profile.get("profile_created", false))

    return {
        "name": name,
        "gender": gender,
        "profile_created": profile_created,
        "display_name": name if name != "" else "Player",
        "gender_label": _gender_label(gender),
    }


static func _gender_label(gender: String) -> String:
    if gender == "male":
        return "Male"
    if gender == "female":
        return "Female"
    return "Unselected"






