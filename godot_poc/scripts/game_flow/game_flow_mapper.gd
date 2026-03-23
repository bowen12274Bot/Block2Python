extends RefCounted
class_name GameFlowMapper


static func map_game_state(state: Dictionary) -> Dictionary:
    var meta: Dictionary = {
        "mode": str(state.get("mode", "")),
        "quest_id": str(state.get("quest_id", "")),
        "node_id": str(state.get("node_id", "")),
        "node_title": str(state.get("node_title", "")),
    }

    var player_profile_view: Dictionary = _build_player_profile_view(state)
    var scene_view: Dictionary = _build_scene_view(state, meta)
    var demo_view: Dictionary = _build_demo_view(state)
    var challenge_view: Dictionary = _build_challenge_view(state)
    var action_view: Dictionary = build_action_view(state)

    return {
        "meta": meta,
        "player_profile_view": player_profile_view,
        "scene_view": scene_view,
        "demo_view": demo_view,
        "challenge_view": challenge_view,
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


static func _build_scene_view(state: Dictionary, meta: Dictionary) -> Dictionary:
    var lines: Array[String] = []
    var scene_title: String = "No active scene"
    var scene_id: String = ""
    var mode_value: String = str(meta.get("mode", ""))
    var node_title: String = str(meta.get("node_title", ""))
    var dialogue_views: Array[Dictionary] = []

    var scene: Variant = state.get("scene", null)
    if scene is Dictionary:
        scene_id = str(scene.get("scene_id", ""))
        scene_title = str(scene.get("title", "No active scene"))
        var dialogue_blocks: Variant = scene.get("dialogue_blocks", [])
        if dialogue_blocks is Array:
            for dialogue_block_variant in dialogue_blocks:
                if dialogue_block_variant is Dictionary:
                    var dialogue_view: Dictionary = _build_dialogue_view(dialogue_block_variant)
                    var speaker: String = str(dialogue_view.get("speaker", ""))
                    var text: String = str(dialogue_view.get("text", ""))
                    lines.append("- %s: %s" % [speaker, text])
                    dialogue_views.append(dialogue_view)

    var body: String = "Current state is not in scene mode."
    if mode_value == "scene":
        body = "Scene mode active, but no dialogue blocks are available."
        if not lines.is_empty():
            body = "
".join(lines)

    var current_index: int = 0
    var total_blocks: int = dialogue_views.size()
    var current_dialogue: Dictionary = {}
    if not dialogue_views.is_empty():
        current_dialogue = dialogue_views[0]

    var background_view: Dictionary = _build_background_view(current_dialogue)
    var left_actor_view: Dictionary = _build_actor_slot_view(current_dialogue, "left")
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
        "right_actor": right_actor_view,
        "dialogue": current_dialogue,
        "dialogue_blocks": dialogue_views,
        "continue_hint_text": "Click to continue",
    }


static func _build_demo_view(state: Dictionary) -> Dictionary:
    var demo_id: String = ""
    var title: String = "Demo Placeholder"
    var body: String = "This demo flow is not defined yet."
    var current_level_id: String = ""
    var demo: Variant = state.get("demo", null)
    if demo is Dictionary:
        demo_id = str(demo.get("demo_id", ""))
        title = str(demo.get("title", title))
        body = str(demo.get("body", body))
        current_level_id = str(demo.get("current_level_id", ""))

    return {
        "demo_id": demo_id,
        "title": title,
        "body": body,
        "current_level_id": current_level_id,
    }


static func _build_challenge_view(state: Dictionary) -> Dictionary:
    var challenge_title: String = "Challenge"
    var level_label: String = "Waiting for challenge mode."
    var prompt_body: String = "No challenge prompt loaded yet."
    var challenge_type: String = ""
    var current_level_id: String = ""
    var challenge: Variant = state.get("challenge", null)
    if challenge is Dictionary:
        challenge_type = str(challenge.get("challenge_type", ""))
        challenge_title = str(challenge.get("current_level_title", "Challenge"))
        current_level_id = str(challenge.get("current_level_id", ""))
        if current_level_id != "":
            level_label = "level_id: %s" % current_level_id
        var current_level_prompt: String = str(challenge.get("current_level_prompt", ""))
        if current_level_prompt != "":
            prompt_body = current_level_prompt

    var mode_value: String = str(state.get("mode", ""))

    return {
        "title": challenge_title,
        "level_label": level_label,
        "prompt_body": prompt_body,
        "challenge_type": challenge_type,
        "current_level_id": current_level_id,
        "toolbox_allowed": challenge_type == "practice",
        "code_editable": mode_value == "challenge" and current_level_id != "",
    }


static func build_action_view(state: Dictionary) -> Dictionary:
    var raw_actions: Variant = state.get("available_actions", null)
    if raw_actions is Dictionary:
        return {
            "can_advance": bool(raw_actions.get("advance", false)),
            "can_submit": bool(raw_actions.get("submit", false)),
        }

    return {
        "can_advance": false,
        "can_submit": false,
    }


static func _gender_label(gender: String) -> String:
    if gender == "male":
        return "Male"
    if gender == "female":
        return "Female"
    return "Unselected"


static func _build_dialogue_view(dialogue_block_variant: Dictionary) -> Dictionary:
    var portrait_id: String = str(dialogue_block_variant.get("portrait_id", ""))
    var expression: String = str(dialogue_block_variant.get("expression", ""))
    var emphasis: String = str(dialogue_block_variant.get("emphasis", "normal"))
    var speaker_side: String = str(dialogue_block_variant.get("speaker_side", ""))
    if speaker_side == "":
        speaker_side = _infer_speaker_side(dialogue_block_variant)

    return {
        "speaker": str(dialogue_block_variant.get("speaker", "")),
        "text": str(dialogue_block_variant.get("text", "")),
        "portrait_id": portrait_id,
        "expression": expression,
        "emphasis": emphasis,
        "speaker_side": speaker_side,
        "background_id": str(dialogue_block_variant.get("background_id", "")),
        "left_actor": _build_actor_view(dialogue_block_variant, "left", speaker_side, portrait_id, expression),
        "right_actor": _build_actor_view(dialogue_block_variant, "right", speaker_side, portrait_id, expression),
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


static func _build_actor_view(dialogue_block_variant: Dictionary, side: String, speaker_side: String, portrait_id: String, expression: String) -> Dictionary:
    var actor_key: String = "%s_actor" % side
    var actor_value: Variant = dialogue_block_variant.get(actor_key, {})
    if actor_value is Dictionary:
        var actor_dict: Dictionary = actor_value
        return {
            "actor_id": str(actor_dict.get("actor_id", "")),
            "display_name": _display_name_from_actor(actor_dict, dialogue_block_variant, side, speaker_side),
            "portrait_id": str(actor_dict.get("portrait_id", portrait_id if side == speaker_side else "")),
            "image_path": "",
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


static func _infer_speaker_side(dialogue_block_variant: Dictionary) -> String:
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
