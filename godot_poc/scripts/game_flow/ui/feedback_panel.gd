extends PanelContainer
class_name FeedbackPanel

const SUCCESS_COLOR := Color(0.462745, 0.870588, 0.611765, 0.95)
const ERROR_COLOR := Color(1, 0.486275, 0.486275, 0.95)
const IDLE_COLOR := Color(0.72549, 0.756863, 0.854902, 0.92)

@onready var feedback_title: Label = $FeedbackMargin/FeedbackRoot/HeaderRow/FeedbackTitle
@onready var status_badge: Label = $FeedbackMargin/FeedbackRoot/HeaderRow/StatusBadge/StatusBadgeMargin/StatusBadgeLabel
@onready var feedback_text: RichTextLabel = $FeedbackMargin/FeedbackRoot/FeedbackText


func show_feedback(feedback_view: Dictionary) -> void:
	feedback_title.text = str(feedback_view.get("title", "Feedback"))
	status_badge.text = str(feedback_view.get("status_text", "Idle"))
	feedback_text.text = str(feedback_view.get("content_text", ""))
	_apply_status_style(bool(feedback_view.get("is_success", false)), str(feedback_view.get("feedback_state", "idle")))


func _apply_status_style(is_success: bool, feedback_state: String) -> void:
	if feedback_state == "idle":
		status_badge.modulate = IDLE_COLOR
	elif is_success:
		status_badge.modulate = SUCCESS_COLOR
	else:
		status_badge.modulate = ERROR_COLOR
