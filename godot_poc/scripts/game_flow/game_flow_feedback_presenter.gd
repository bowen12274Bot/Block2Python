extends RefCounted
class_name GameFlowFeedbackPresenter


static func empty_feedback_view(message: String) -> Dictionary:
	return {
		"title": "Diagnostic Output",
		"kind": "idle",
		"feedback_state": "idle",
		"status_text": "待命中",
		"is_success": false,
		"content_text": message,
		"details": {},
	}


static func build_feedback_view(view_model: Dictionary, response: Dictionary) -> Dictionary:
	var ok_value: bool = bool(response.get("ok", false))
	if not ok_value:
		return {
			"title": "Request Failed",
			"kind": "error",
			"feedback_state": "submit_error",
			"status_text": "提交錯誤",
			"is_success": false,
			"content_text": str(response.get("error", "Unknown error")),
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

	var kind: String = str(last_submission.get("kind", "submission"))
	var output_text: String = str(last_submission.get("output_text", ""))
	var analysis_status: String = str(last_submission.get("analysis_status", ""))
	var judge_status: String = str(last_submission.get("judge_status", ""))
	var analysis_summary: String = str(last_submission.get("analysis_summary", ""))
	var judge_summary: String = str(last_submission.get("judge_summary", ""))
	var source_type: String = "toolbox" if kind == "toolbox_run" else ("python" if kind == "run_result" or kind == "submission" else "system")
	var has_runtime_error: bool = _has_runtime_error(analysis_status, judge_status)
	var feedback_state: String = _feedback_state_for_submission(kind, has_runtime_error, judge_status)
	var display_output_text: String = _display_output_text_from_submission(output_text)
	var emitted_output: bool = bool(details.get("emitted_output", display_output_text != ""))
	var status_text: String = _status_text_for_state(feedback_state, source_type, emitted_output)
	var readable_error_text: String = _readable_error_text(
		feedback_state,
		has_runtime_error,
		analysis_status,
		analysis_summary,
		judge_status,
		judge_summary,
		output_text
	)
	var content_text: String = _content_text_for_state(
		feedback_state,
		display_output_text,
		readable_error_text
	)

	return {
		"title": "Diagnostic Output",
		"kind": kind,
		"feedback_state": feedback_state,
		"status_text": status_text,
		"is_success": feedback_state == "run_success" or feedback_state == "submit_success",
		"content_text": content_text,
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
			"feedback_state": "idle",
			"status_text": "待命中",
			"is_success": false,
			"content_text": "Scene mode\n\nUse Advance to continue the story flow.",
			"details": {},
		}
	if mode_value == "challenge":
		return {
			"title": "Diagnostic Output",
			"kind": "guidance",
			"feedback_state": "idle",
			"status_text": "待命中",
			"is_success": false,
			"content_text": "先執行程式或提交答案。",
			"details": {},
		}
	if mode_value == "demo":
		return {
			"title": "Demo Guidance",
			"kind": "guidance",
			"feedback_state": "idle",
			"status_text": "待命中",
			"is_success": false,
			"content_text": "Review the demo content and press Continue to move into practice.",
			"details": {},
		}

	return {
		"title": "Diagnostic Output",
		"kind": "guidance",
		"feedback_state": "idle",
		"status_text": "待命中",
		"is_success": false,
		"content_text": "先執行程式或提交答案。",
		"details": {},
	}


static func _has_runtime_error(analysis_status: String, judge_status: String) -> bool:
	return (
		analysis_status == "SYNTAX_ERROR"
		or analysis_status == "INTERNAL_ERROR"
		or judge_status == "RE"
		or judge_status == "TLE"
		or judge_status == "MLE"
		or judge_status == "INTERNAL_ERROR"
	)


static func _feedback_state_for_submission(kind: String, has_runtime_error: bool, judge_status: String) -> String:
	if kind == "run_result" or kind == "toolbox_run":
		return "run_error" if has_runtime_error else "run_success"
	if has_runtime_error:
		return "submit_error"
	if judge_status == "AC":
		return "submit_success"
	if judge_status == "WA":
		return "submit_rejected"
	return "submit_error"


static func _status_text_for_state(feedback_state: String, source_type: String, emitted_output: bool) -> String:
	match feedback_state:
		"run_success":
			if not emitted_output:
				return "沒有輸出"
			return "工具包成功輸出" if source_type == "toolbox" else "成功輸出"
		"run_error":
			return "工具包執行錯誤" if source_type == "toolbox" else "執行錯誤"
		"submit_success":
			return "提交成功"
		"submit_error":
			return "提交錯誤"
		"submit_rejected":
			return "提交失敗"
		_:
			return "待命中"


static func _display_output_text_from_submission(output_text: String) -> String:
	var lines: PackedStringArray = output_text.split("\n")
	var visible_lines: Array[String] = []
	for raw_line in lines:
		var line: String = raw_line.strip_edges()
		if line == "":
			continue
		if line.ends_with(":"):
			continue
		if line.begins_with("analysis="):
			continue
		if line.begins_with("judge="):
			continue
		if line.begins_with("source="):
			continue
		visible_lines.append(line)
	return "\n".join(visible_lines)


static func _readable_error_text(
	feedback_state: String,
	has_runtime_error: bool,
	analysis_status: String,
	analysis_summary: String,
	judge_status: String,
	judge_summary: String,
	output_text: String
) -> String:
	if feedback_state == "submit_rejected":
		return _humanize_submit_rejected_text(judge_summary, output_text)

	if has_runtime_error:
		if analysis_status == "SYNTAX_ERROR" and analysis_summary != "":
			return analysis_summary
		if judge_summary != "":
			return judge_summary
		if analysis_summary != "":
			return analysis_summary
	return _display_output_text_from_submission(output_text)


static func _humanize_submit_rejected_text(judge_summary: String, output_text: String) -> String:
	var summary_text: String = judge_summary.strip_edges()
	if summary_text != "":
		var case_match: RegExMatch = _wrong_answer_case_regex().search(summary_text)
		if case_match != null:
			var failed_case_index: int = int(case_match.get_string(1))
			return "第 %d 筆測試未通過。" % [failed_case_index + 1]
		return summary_text

	var display_output_text: String = _display_output_text_from_submission(output_text)
	if display_output_text != "":
		return display_output_text
	return "輸出與預期結果不一致。"


static func _content_text_for_state(feedback_state: String, output_text: String, error_text: String) -> String:
	match feedback_state:
		"idle":
			return "先執行程式或提交答案。"
		"run_success":
			if output_text != "":
				return output_text
			return ""
		"submit_success":
			if output_text != "":
				return output_text
			return "答案正確，已完成本題。"
		"submit_rejected":
			if error_text != "":
				return error_text
			return "輸出與預期結果不一致。"
		"run_error", "submit_error":
			if error_text != "":
				return error_text
			return "發生未知錯誤。"
		_:
			return output_text if output_text != "" else "先執行程式或提交答案。"


static func _wrong_answer_case_regex() -> RegEx:
	var wrong_answer_regex := RegEx.new()
	wrong_answer_regex.compile("(?i)wrong answer at case\\s+(\\d+)\\.?")
	return wrong_answer_regex
