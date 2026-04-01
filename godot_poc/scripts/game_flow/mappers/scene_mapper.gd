extends RefCounted
class_name GameFlowSceneMapper


static func build_scene_view(state: Dictionary, meta: Dictionary) -> Dictionary:
    var lines: Array[String] = []
    var scene_title: String = "No active scene"
    var scene_id: String = ""
    var mode_value: String = str(meta.get("mode", ""))
    var node_title: String = str(meta.get("node_title", ""))
    var dialogue_views: Array[Dictionary] = []
    var player_gender: String = ""
    var player_profile: Variant = state.get("player_profile", {})
    if player_profile is Dictionary:
        player_gender = str(player_profile.get("gender", ""))

    var scene: Variant = state.get("scene", null)
    if scene is Dictionary:
        scene_id = str(scene.get("scene_id", ""))
        scene_title = str(scene.get("title", "No active scene"))
        var dialogue_blocks: Variant = scene.get("dialogue_blocks", [])
        if dialogue_blocks is Array:
            for dialogue_block_variant in dialogue_blocks:
                if dialogue_block_variant is Dictionary:
                    var dialogue_view: Dictionary = _build_dialogue_view(dialogue_block_variant, player_gender)
                    var speaker: String = str(dialogue_view.get("speaker", ""))
                    var text: String = str(dialogue_view.get("text", ""))
                    lines.append("- %s: %s" % [speaker, text])
                    dialogue_views.append(dialogue_view)

    var body: String = "Current state is not in scene mode."
    if mode_value == "scene":
        body = "Scene mode active, but no dialogue blocks are available."
        if not lines.is_empty():
            body = "\n".join(lines)

    var current_index: int = 0
    var total_blocks: int = dialogue_views.size()
    var current_dialogue: Dictionary = {}
    if not dialogue_views.is_empty():
        current_dialogue = dialogue_views[0]

    var background_view: Dictionary = _build_background_view(current_dialogue)
    var left_actor_view: Dictionary = _build_actor_slot_view(current_dialogue, "left")
    var center_actor_view: Dictionary = _build_actor_slot_view(current_dialogue, "center")
    var right_actor_view: Dictionary = _build_actor_slot_view(current_dialogue, "right")

    return {
        "mode_label": "Mode: %s" % mode_value,
        "node_label": "Node: %s" % node_title,
        "title": scene_title,
        "body": body,
        "scene_id": scene_id,
        "current_index": current_index,
        "total_blocks": total_blocks,
        "can_advance": total_blocks > 0,
        "background": background_view,
        "left_actor": left_actor_view,
        "center_actor": center_actor_view,
        "right_actor": right_actor_view,
        "dialogue": current_dialogue,
        "dialogue_blocks": dialogue_views,
        "continue_hint_text": "Click to continue",
        "show_mission_brief_on_complete": _should_show_mission_brief(state, meta),
        "mission_brief_title": _scene_mission_brief_title(scene),
        "mission_brief_text": _scene_mission_brief_text(scene),
    }


static func _scene_mission_brief_title(scene: Variant) -> String:
    if scene is Dictionary:
        return str(scene.get("mission_statement_title", "Mission"))
    return "Mission"


static func _scene_mission_brief_text(scene: Variant) -> String:
    if scene is Dictionary:
        return str(scene.get("mission_statement_text", ""))
    return ""


static func _should_show_mission_brief(state: Dictionary, meta: Dictionary) -> bool:
    if not bool(state.get("intro_completed", false)):
        return false
    if str(meta.get("mode", "")) != "scene":
        return false
    var scene: Variant = state.get("scene", null)
    if scene is Dictionary:
        var mission_statement_scene_id: Variant = scene.get("mission_statement_scene_id", null)
        if mission_statement_scene_id is String:
            return String(mission_statement_scene_id).strip_edges() != ""
    return false


static func _build_dialogue_view(dialogue_block_variant: Dictionary, player_gender: String) -> Dictionary:
    var portrait_id: String = _resolve_portrait_id(str(dialogue_block_variant.get("portrait_id", "")), player_gender)
    var expression: String = str(dialogue_block_variant.get("expression", ""))
    var emphasis: String = str(dialogue_block_variant.get("emphasis", "normal"))
    var speaker_side: String = _normalize_speaker_side(str(dialogue_block_variant.get("speaker_side", "")), dialogue_block_variant)

    return {
        "speaker": str(dialogue_block_variant.get("speaker", "")),
        "text": str(dialogue_block_variant.get("text", "")),
        "portrait_id": portrait_id,
        "expression": expression,
        "emphasis": emphasis,
        "speaker_side": speaker_side,
        "background_id": str(dialogue_block_variant.get("background_id", "")),
        "left_actor": _build_actor_view(dialogue_block_variant, "left", speaker_side, portrait_id, expression, player_gender),
        "center_actor": _build_actor_view(dialogue_block_variant, "center", speaker_side, portrait_id, expression, player_gender),
        "right_actor": _build_actor_view(dialogue_block_variant, "right", speaker_side, portrait_id, expression, player_gender),
    }


static func _build_background_view(dialogue_view: Dictionary) -> Dictionary:
    return {
        "background_id": str(dialogue_view.get("background_id", "")),
        "image_path": "",
    }


static func _build_actor_slot_view(dialogue_view: Dictionary, side: String) -> Dictionary:
    var actor_value: Variant = dialogue_view.get("%s_actor" % side, {})
    if actor_value is Dictionary:
        return actor_value
    return _default_actor_view(side)


static func _build_actor_view(dialogue_block_variant: Dictionary, side: String, speaker_side: String, portrait_id: String, expression: String, player_gender: String) -> Dictionary:
    var actor_key: String = "%s_actor" % side
    var actor_value: Variant = dialogue_block_variant.get(actor_key, {})
    if actor_value is Dictionary:
        var actor_dict: Dictionary = actor_value
        var actor_portrait_id := _resolve_portrait_id(str(actor_dict.get("portrait_id", portrait_id if side == speaker_side else "")), player_gender)
        return {
            "actor_id": str(actor_dict.get("actor_id", "")),
            "display_name": _display_name_from_actor(actor_dict, dialogue_block_variant, side, speaker_side),
            "portrait_id": actor_portrait_id,
            "image_path": str(actor_dict.get("image_path", "")),
            "pose_id": str(actor_dict.get("pose_id", "default")),
            "expression_id": str(actor_dict.get("expression_id", expression if side == speaker_side else "")),
            "visual_state": str(actor_dict.get("visual_state", _default_visual_state(side, speaker_side))),
            "side": side,
        }

    if side == speaker_side:
        return {
            "actor_id": _actor_id_from_portrait_id(portrait_id),
            "display_name": str(dialogue_block_variant.get("speaker", "")),
            "portrait_id": portrait_id,
            "image_path": "",
            "pose_id": "default",
            "expression_id": expression,
            "visual_state": "focus",
            "side": side,
        }

    return _default_actor_view(side)


static func _default_actor_view(side: String) -> Dictionary:
    return {
        "actor_id": "",
        "display_name": "",
        "portrait_id": "",
        "image_path": "",
        "pose_id": "default",
        "expression_id": "",
        "visual_state": "hidden",
        "side": side,
    }


static func _resolve_portrait_id(portrait_id: String, player_gender: String) -> String:
    if portrait_id != "player-default":
        return portrait_id
    if player_gender == "male":
        return "player-male-default"
    if player_gender == "female":
        return "player-female-default"
    return "player-female-default"


static func _display_name_from_actor(actor_dict: Dictionary, dialogue_block_variant: Dictionary, side: String, speaker_side: String) -> String:
    var display_name: String = str(actor_dict.get("display_name", ""))
    if display_name != "":
        return display_name
    if side == speaker_side:
        return str(dialogue_block_variant.get("speaker", ""))
    return ""


static func _default_visual_state(side: String, speaker_side: String) -> String:
    if side == speaker_side:
        return "focus"
    if speaker_side == "":
        return "hidden"
    return "dim"


static func _normalize_speaker_side(raw_side: String, dialogue_block_variant: Dictionary) -> String:
    var normalized := raw_side.strip_edges().to_lower()
    if normalized in ["left", "center", "right"]:
        return normalized
    return _infer_speaker_side(dialogue_block_variant)


static func _infer_speaker_side(dialogue_block_variant: Dictionary) -> String:
    if dialogue_block_variant.get("center_actor", null) is Dictionary:
        return "center"
    var portrait_id: String = str(dialogue_block_variant.get("portrait_id", ""))
    if portrait_id.begins_with("byte"):
        return "left"
    if portrait_id.begins_with("player"):
        return "right"
    return ""


static func _actor_id_from_portrait_id(portrait_id: String) -> String:
    if portrait_id == "":
        return ""
    return portrait_id.split("-")[0]
