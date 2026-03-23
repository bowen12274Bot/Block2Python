extends Control
class_name DemoScreen

signal advance_requested()
signal back_requested()

@onready var status_label: Label = $Margin/Root/StatusLabel
@onready var title_label: Label = $Margin/Root/DemoPanel/DemoMargin/DemoRoot/TitleLabel
@onready var summary_label: RichTextLabel = $Margin/Root/DemoPanel/DemoMargin/DemoRoot/SummaryLabel
@onready var continue_button: Button = $Margin/Root/Buttons/ContinueButton
@onready var back_button: Button = $Margin/Root/Buttons/BackButton

func _ready() -> void:
	continue_button.pressed.connect(_on_continue_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)

func show_demo(demo_view: Dictionary) -> void:
	title_label.text = str(demo_view.get("title", "Demo Placeholder"))
	var sections: Array[String] = []
	_append_demo_section(sections, "Prompt", str(demo_view.get("prompt", "")))
	_append_demo_section(sections, "Learning", str(demo_view.get("learning_markdown", "")))
	_append_demo_section(sections, "Story Intro", str(demo_view.get("story_intro_markdown", "")))
	_append_demo_section(sections, "Story Outro", str(demo_view.get("story_outro_markdown", "")))
	if sections.is_empty():
		sections.append(str(demo_view.get("body", "This demo flow is not defined yet.")))
	var demo_id: String = str(demo_view.get("demo_id", ""))
	var level_id: String = str(demo_view.get("level_id", demo_view.get("current_level_id", "")))
	var group_id: String = str(demo_view.get("group_id", ""))
	sections.append("demo_id: %s" % (demo_id if demo_id != "" else "-"))
	sections.append("group_id: %s" % (group_id if group_id != "" else "-"))
	sections.append("level_id: %s" % (level_id if level_id != "" else "-"))
	summary_label.text = "\n\n".join(sections)

func show_placeholder(message: String) -> void:
	title_label.text = "Demo Placeholder"
	summary_label.text = message

func set_status(text: String) -> void:
	status_label.text = text

func set_can_advance(can_advance: bool) -> void:
	continue_button.disabled = not can_advance

func set_can_go_back(can_go_back: bool) -> void:
	back_button.disabled = not can_go_back

func _on_continue_button_pressed() -> void:
	status_label.text = "Status: continuing demo flow..."
	advance_requested.emit()

func _on_back_button_pressed() -> void:
	status_label.text = "Status: returning to map..."
	back_requested.emit()

func _append_demo_section(sections: Array[String], title: String, value: String) -> void:
	if value.strip_edges() == "":
		return
	sections.append("%s\n%s" % [title, value])
