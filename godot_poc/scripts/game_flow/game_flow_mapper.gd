extends RefCounted
class_name GameFlowMapper


static func map_game_state(state: Dictionary) -> Dictionary:
    var meta: Dictionary = {
        "mode": str(state.get("mode", "")),
        "quest_id": str(state.get("quest_id", "")),
        "node_id": str(state.get("node_id", "")),
        "node_title": str(state.get("node_title", "")),
    }

    var scene_view: Dictionary = _build_scene_view(state, meta)
    var challenge_view: Dictionary = _build_challenge_view(state)
    var action_view: Dictionary = build_action_view(state)

    return {
        "meta": meta,
        "scene_view": scene_view,
        "challenge_view": challenge_view,
        "action_view": action_view,
    }


static func _build_scene_view(state: Dictionary, meta: Dictionary) -> Dictionary:
    var lines: Array[String] = []
    var scene_title: String = "No active scene"
    var mode_value: String = str(meta.get("mode", ""))
    var node_title: String = str(meta.get("node_title", ""))

    var scene: Variant = state.get("scene", null)
    if scene is Dictionary:
        scene_title = str(scene.get("title", "No active scene"))
        var dialogue_blocks: Variant = scene.get("dialogue_blocks", [])
        if dialogue_blocks is Array:
            for dialogue_block_variant in dialogue_blocks:
                if dialogue_block_variant is Dictionary:
                    var speaker: String = str(dialogue_block_variant.get("speaker", ""))
                    var text: String = str(dialogue_block_variant.get("text", ""))
                    lines.append("- %s: %s" % [speaker, text])

    var body: String = "Current state is not in scene mode."
    if mode_value == "scene":
        body = "Scene mode active, but no dialogue blocks are available."
        if not lines.is_empty():
            body = "\n".join(lines)

    return {
        "mode_label": "Mode: %s" % mode_value,
        "node_label": "Node: %s" % node_title,
        "title": scene_title,
        "body": body,
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
