extends RefCounted
class_name StatusLabelHelper


static func label_for_status(status_key: String) -> String:
	match status_key:
		"current":
			return "Current"
		"completed":
			return "Completed"
		"available":
			return "Available"
		"reviewing":
			return "Reviewing"
		_:
			return "Locked"
