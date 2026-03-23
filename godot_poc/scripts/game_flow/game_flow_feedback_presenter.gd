extends RefCounted
class_name GameFlowFeedbackPresenter


static func empty_feedback_view(message: String) -> Dictionary:
    return {
        "title": "Diagnostic Output",
        "kind": "idle",
        "status_label": "Idle",
        "body": message,
        "details": {},
    }


static func build_feedback_view(view_model: Dictionary, response: Dictionary) -> Dictionary:
    var ok_value: bool = bool(response.get("ok", false))
    if not ok_value:
        return {
            "title": "Request Failed",
            "kind": "error",
            "status_label": "Request Failed",
            "body": str(response.get("error", "Unknown error")),
            "details": {},
        }

    var state: Variant = response.get("state", null)
    if state is Dictionary:
        var last_submission: Variant = state.get("last_submission", null)
        if last_submission is Dictionary:
            return _build_submission_feedback(last_submission)

    return _build_guidance_feedback(view_model)


static func _build_submission_feedback(last_submission: Dictionary) -> Dictionary:
    var details: Dictionary = {}
    var raw_details: Variant = last_submission.get("details", {})
    if raw_details is Dictionary:
        details = raw_details

    var title: String = "Diagnostic Output"
    var kind: String = str(last_submission.get("kind", "submission"))
    if kind == "run_result":
        title = "Run Output"
    elif kind == "toolbox_run":
        title = "Tool Kit Output"
    elif kind == "submission":
        title = "Submission Result"

    var body_parts: Array[String] = []
    body_parts.append("status: %s" % str(last_submission.get("status_label", "")))
    var output_text: String = str(last_submission.get("output_text", ""))
    if output_text != "":
        body_parts.append(output_text)
    var analysis_summary: String = str(last_submission.get("analysis_summary", ""))
    if analysis_summary != "":
        body_parts.append("analysis: %s" % analysis_summary)
    var judge_summary: String = str(last_submission.get("judge_summary", ""))
    if judge_summary != "":
        body_parts.append("judge: %s" % judge_summary)
    if not details.is_empty():
        body_parts.append("details: %s" % JSON.stringify(details))

    return {
        "title": title,
        "kind": kind,
        "status_label": str(last_submission.get("status_label", "")),
        "body": "\n\n".join(body_parts),
        "details": details,
    }


static func _build_guidance_feedback(view_model: Dictionary) -> Dictionary:
    var meta: Variant = view_model.get("meta", {})
    var mode_value: String = ""
    if meta is Dictionary:
        mode_value = str(meta.get("mode", ""))
    if mode_value == "scene":
        return {
            "title": "Scene Guidance",
            "kind": "guidance",
            "status_label": "Scene Mode",
            "body": "Scene mode\n\nUse Advance to continue the story flow.",
            "details": {},
        }
    if mode_value == "challenge":
        var practice_view: Dictionary = view_model.get("practice_view", {})
        return {
            "title": "Diagnostic Output",
            "kind": "guidance",
            "status_label": "Practice Mode",
            "body": "Ready. Use Run to inspect output, Submit to clear the level, and Next after a successful submit.\n\n%s" % str(practice_view.get("toolkit_hint", "")),
            "details": {},
        }
    if mode_value == "demo":
        return {
            "title": "Demo Guidance",
            "kind": "guidance",
            "status_label": "Demo Mode",
            "body": "Review the demo content and press Continue to move into practice.",
            "details": {},
        }

    return {
        "title": "Diagnostic Output",
        "kind": "guidance",
        "status_label": "Ready",
        "body": "Request succeeded.",
        "details": {},
    }
