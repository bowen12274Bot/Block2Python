extends RefCounted
class_name GameFlowFeedbackPresenter


static func empty_feedback_view(message: String) -> Dictionary:
    return {
        "title": "Feedback",
        "body": message,
    }


static func build_feedback_view(view_model: Dictionary, response: Dictionary) -> Dictionary:
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
            return _build_submission_feedback(last_submission)

    return _build_guidance_feedback(view_model)


static func _build_submission_feedback(last_submission: Dictionary) -> Dictionary:
    var lines: Array[String] = []
    lines.append("level_id: %s" % str(last_submission.get("level_id", "")))
    if bool(last_submission.get("verification_only", false)):
        lines.append("toolbox verification: true")
        lines.append("answer_correct: %s" % str(bool(last_submission.get("answer_correct", false))))
        lines.append("formal clear granted: false")
    else:
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
        "title": "Toolbox Verification" if bool(last_submission.get("verification_only", false)) else "Submission Result",
        "body": "
".join(lines),
    }


static func _build_guidance_feedback(view_model: Dictionary) -> Dictionary:
    var meta: Variant = view_model.get("meta", {})
    var mode_value: String = ""
    if meta is Dictionary:
        mode_value = str(meta.get("mode", ""))
    if mode_value == "scene":
        return {
            "title": "Scene Guidance",
            "body": "Scene mode

Use Advance to continue the story flow.",
        }
    if mode_value == "challenge":
        return {
            "title": "Challenge Guidance",
            "body": "Challenge mode

Edit the code and press Submit. Use Toolbox in practice levels to test logic without clearing the level.",
        }

    return {
        "title": "Feedback",
        "body": "Request succeeded.",
    }
