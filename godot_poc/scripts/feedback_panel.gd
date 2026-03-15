extends PanelContainer

@onready var feedback_title: Label = $FeedbackMargin/FeedbackRoot/FeedbackTitle
@onready var feedback_text: RichTextLabel = $FeedbackMargin/FeedbackRoot/FeedbackText


func show_feedback(feedback_view: Dictionary) -> void:
    feedback_title.text = str(feedback_view.get("title", "Feedback"))
    feedback_text.text = str(feedback_view.get("body", ""))
