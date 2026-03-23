extends RefCounted
class_name GameFlowFeedbackPresenter


static func empty_feedback_view(message: String) -> Dictionary:
    return {
        "title": "Feedback",
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

    var lines: Array[String] = []
    lines.append("level_id: %s" % str(last_submission.get("level_id", "")))
    lines.append("status: %s" % str(last_submission.get("status_label", "")))
    lines.append("analysis: %s" % str(last_submission.get("analysis_status", "")))
    var analysis_summary: String = str(last_submission.get("analysis_summary", ""))
    if analysis_summary != "":
        lines.append("analysis_summary: %s" % analysis_summary)
    lines.append("judge: %s" % str(last_submission.get("judge_status", "")))
    var judge_summary: String = str(last_submission.get("judge_summary", ""))
    if judge_summary != "":
        lines.append("judge_summary: %s" % judge_summary)
    if bool(last_submission.get("verification_only", false)):
        lines.append("toolbox verification: true")
        lines.append("answer_correct: %s" % str(bool(last_submission.get("answer_correct", false))))
        lines.append("formal clear granted: false")
    else:
        lines.append("cleared: %s" % str(bool(last_submission.get("cleared", false))))
    if not details.is_empty():
        lines.append("details: %s" % JSON.stringify(details))

    return {
        "title": "Toolbox Verification" if bool(last_submission.get("verification_only", false)) else "Submission Result",
        "kind": str(last_submission.get("kind", "submission")),
        "status_label": str(last_submission.get("status_label", "")),
        "body": "\n".join(lines),
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
        return {
            "title": "Practice Guidance",
            "kind": "guidance",
            "status_label": "Practice Mode",
            "body": "Practice mode\n\nEdit the code and press Submit. Use Toolbox in practice levels to verify logic without clearing the level.",
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
        "title": "Feedback",
        "kind": "guidance",
        "status_label": "Ready",
        "body": "Request succeeded.",
        "details": {},
    }

