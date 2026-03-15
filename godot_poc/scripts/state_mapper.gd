extends RefCounted
class_name StateMapper


static func map_game_state(state: Dictionary) -> Dictionary:
    var meta: Dictionary = {
        "mode": str(state.get("mode", "")),
        "quest_id": str(state.get("quest_id", "")),
        "node_id": str(state.get("node_id", "")),
        "node_title": str(state.get("node_title", "")),
    }

    var scene_view: Dictionary = _build_scene_view(state, meta)
    var challenge_view: Dictionary = _build_challenge_view(state)
    var action_view: Dictionary = _build_action_view(state)
    var feedback_view: Dictionary = _build_feedback_view(meta, state)

    return {
        "meta": meta,
        "scene_view": scene_view,
        "challenge_view": challenge_view,
        "feedback_view": feedback_view,
        "action_view": action_view,
    }


static func override_feedback(view_model: Dictionary, response: Dictionary) -> Dictionary:
    var next_view_model: Dictionary = view_model.duplicate(true)
    next_view_model["feedback_view"] = _build_feedback_from_response(next_view_model, response)
    return next_view_model


static func empty_feedback_view(message: String) -> Dictionary:
    return {
        "title": "Feedback",
        "body": message,
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
    var challenge: Variant = state.get("challenge", null)
    if challenge is Dictionary:
        challenge_title = str(challenge.get("current_level_title", "Challenge"))
        var current_level_id: String = str(challenge.get("current_level_id", ""))
        if current_level_id != "":
            level_label = "level_id: %s" % current_level_id
        var current_level_prompt: String = str(challenge.get("current_level_prompt", ""))
        if current_level_prompt != "":
            prompt_body = current_level_prompt

    var raw_actions: Variant = state.get("available_actions", null)
    var can_submit: bool = false
    if raw_actions is Dictionary:
        can_submit = bool(raw_actions.get("submit", false))

    return {
        "title": challenge_title,
        "level_label": level_label,
        "prompt_body": prompt_body,
        "code_editable": can_submit,
    }


static func _build_action_view(state: Dictionary) -> Dictionary:
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


static func _build_feedback_view(meta: Dictionary, state: Dictionary) -> Dictionary:
    return _build_feedback_from_response({
        "meta": meta,
        "action_view": _build_action_view(state),
    }, {"ok": true, "state": state})


static func _build_feedback_from_response(view_model: Dictionary, response: Dictionary) -> Dictionary:
    var ok_value: bool = bool(response.get("ok", false))
    if not ok_value:
        return {
            "title": "Request Failed",
            "body": str(response.get("error", "Unknown error")),
        }

    var state: Variant = response.get("state", null)
    if state is Dictionary:
        var last_submission: Variant = state.get("last_submission", null)
        if last_submission is Dictionary:
            var lines: Array[String] = []
            lines.append("level_id: %s" % str(last_submission.get("level_id", "")))
            lines.append("cleared: %s" % str(bool(last_submission.get("cleared", false))))
            lines.append("analysis: %s" % str(last_submission.get("analysis_status", "")))
            var analysis_summary: String = str(last_submission.get("analysis_summary", ""))
            if analysis_summary != "":
                lines.append("analysis_summary: %s" % analysis_summary)
            lines.append("judge: %s" % str(last_submission.get("judge_status", "")))
            var judge_summary: String = str(last_submission.get("judge_summary", ""))
            if judge_summary != "":
                lines.append("judge_summary: %s" % judge_summary)
            return {
                "title": "Submission Result",
                "body": "\n".join(lines),
            }

    var meta: Variant = view_model.get("meta", {})
    var mode_value: String = ""
    if meta is Dictionary:
        mode_value = str(meta.get("mode", ""))
    if mode_value == "scene":
        return {
            "title": "Scene Guidance",
            "body": "Scene mode\n\nUse Advance to continue the story flow.",
        }
    if mode_value == "challenge":
        return {
            "title": "Challenge Guidance",
            "body": "Challenge mode\n\nEdit the code and press Submit.",
        }

    return {
        "title": "Feedback",
        "body": "Request succeeded.",
    }