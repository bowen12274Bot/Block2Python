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
    var practice_view: Dictionary = _build_practice_view(state)
    var action_view: Dictionary = build_action_view(state)

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


static func _build_scene_view(state: Dictionary, meta: Dictionary) -> Dictionary:
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


static func _build_demo_view(state: Dictionary) -> Dictionary:
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
        demo_view["unlock_blocks"] = _normalize_unlock_blocks(demo.get("unlock_blocks", _default_demo_unlock_blocks(str(demo_view.get("group_id", "")))))

    return demo_view


static func _normalize_unlock_blocks(value: Variant) -> Array[Dictionary]:
    var blocks: Array[Dictionary] = []
    if value is Array:
        for block_variant in value:
            if block_variant is Dictionary:
                blocks.append(block_variant)
    return blocks


static func _default_demo_unlock_blocks(group_id: String) -> Array[Dictionary]:
    match group_id:
        "group-01":
            return [
                {"title": "print", "description": "Output text to the screen."},
                {"title": "input", "description": "Read user input into your program."},
            ]
        _:
            return []


static func _build_practice_view(state: Dictionary) -> Dictionary:
    var practice_title: String = "Practice"
    var practice_view: Dictionary = {
        "title": practice_title,
        "group_id": "",
        "level_id": "",
        "level_title": "",
        "prompt": "",
        "progress_current": 0,
        "progress_total": 0,
        "progress_label": "Progress: --",
        "is_review_mode": false,
        "toolbox_allowed": false,
        "toolbox_used": false,
        "can_run": false,
        "can_submit": false,
        "can_next": false,
        "challenge_type": "",
        "mission_text": "No mission loaded yet.",
        "battery_percent": 0,
        "battery_threshold_percent": 80,
        "assistant_messages": [],
        "assistant_chat_text": "Byte: Practice assistant is standing by.",
        "toolkit_hint": "Open the toolkit when you need help exploring a block-based solution.",
        "current_level_id": "",
        "current_level_title": "",
        "current_level_prompt": "",
    }

    var practice: Variant = state.get("practice", null)
    if practice is Dictionary:
        practice_view["challenge_type"] = str(practice.get("challenge_type", ""))
        practice_view["group_id"] = str(practice.get("group_id", ""))
        practice_view["level_id"] = str(practice.get("level_id", practice.get("current_level_id", "")))
        practice_view["level_title"] = str(practice.get("level_title", practice.get("current_level_title", "")))
        practice_view["prompt"] = str(practice.get("prompt", practice.get("current_level_prompt", "")))
        practice_view["progress_current"] = int(practice.get("progress_current", 0))
        practice_view["progress_total"] = int(practice.get("progress_total", 0))
        practice_view["is_review_mode"] = bool(practice.get("is_review_mode", false))
        practice_view["toolbox_allowed"] = bool(practice.get("toolbox_allowed", false))
        practice_view["toolbox_used"] = bool(practice.get("toolbox_used", false))
        practice_view["can_run"] = bool(practice.get("can_run", false))
        practice_view["can_submit"] = bool(practice.get("can_submit", false))
        practice_view["can_next"] = bool(practice.get("can_next", false))
        practice_view["mission_text"] = str(practice.get("mission_text", practice_view["prompt"]))
        practice_view["battery_percent"] = int(practice.get("battery_percent", 0))
        practice_view["battery_threshold_percent"] = int(practice.get("battery_threshold_percent", 80))
        practice_view["current_level_id"] = str(practice.get("current_level_id", practice_view["level_id"]))
        practice_view["current_level_title"] = str(practice.get("current_level_title", practice_view["level_title"]))
        practice_view["current_level_prompt"] = str(practice.get("current_level_prompt", practice_view["prompt"]))
        practice_view["title"] = str(practice_view["level_title"] if practice_view["level_title"] != "" else practice_title)

        var assistant_messages: Array[String] = []
        var raw_messages: Variant = practice.get("assistant_messages", [])
        if raw_messages is Array:
            for message_variant in raw_messages:
                assistant_messages.append(str(message_variant))
        practice_view["assistant_messages"] = assistant_messages
        practice_view["assistant_chat_text"] = "\n\n".join(assistant_messages) if not assistant_messages.is_empty() else "Byte: Practice assistant is standing by."
        practice_view["toolkit_hint"] = "Tool Kit is ready for block-based runs." if bool(practice_view["toolbox_allowed"]) else "Tool Kit is unavailable for this practice level."

    var current_level_id: String = str(practice_view.get("current_level_id", ""))
    var progress_total: int = int(practice_view.get("progress_total", 0))
    var progress_current: int = int(practice_view.get("progress_current", 0))
    if progress_total > 0 and progress_current > 0:
        practice_view["progress_label"] = "Progress: %d/%d" % [progress_current, progress_total]
    elif current_level_id != "":
        practice_view["progress_label"] = "Progress: %s" % current_level_id

    var mode_value: String = str(state.get("mode", ""))
    practice_view["code_editable"] = mode_value == "challenge" and current_level_id != ""

    return practice_view


static func build_action_view(state: Dictionary) -> Dictionary:
    var raw_actions: Variant = state.get("available_actions", null)
    if raw_actions is Dictionary:
        return {
            "can_advance": bool(raw_actions.get("advance", false)),
            "can_run": bool(raw_actions.get("run", false)),
            "can_submit": bool(raw_actions.get("submit", false)),
            "can_next": bool(raw_actions.get("next_level", false)),
        }

    return {
        "can_advance": false,
        "can_run": false,
        "can_submit": false,
        "can_next": false,
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
        return str(scene.get("mission_statement_scene_id", "")) != ""
    return false


static func _gender_label(gender: String) -> String:
    if gender == "male":
        return "Male"
    if gender == "female":
        return "Female"
    return "Unselected"


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