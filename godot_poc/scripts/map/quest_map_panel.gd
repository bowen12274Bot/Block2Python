extends PanelContainer
class_name QuestMapPanel

signal node_pressed(node_id: String)
signal group_pressed(group_id: String)

@onready var quest_title: Label = $MapMargin/MapRoot/MapHeader/QuestTitle
@onready var mode_label: Label = $MapMargin/MapRoot/MapHeader/MetaRow/ModeLabel
@onready var current_node_label: Label = $MapMargin/MapRoot/MapHeader/MetaRow/CurrentNodeLabel
@onready var summary_label: Label = $MapMargin/MapRoot/SummaryLabel
@onready var groups_summary_label: Label = $MapMargin/MapRoot/GroupsSection/GroupsSummaryLabel
@onready var groups_container: HFlowContainer = $MapMargin/MapRoot/GroupsSection/GroupsContainer
@onready var nodes_title: Label = $MapMargin/MapRoot/NodesTitle
@onready var nodes_container: HFlowContainer = $MapMargin/MapRoot/NodesContainer


func show_map(map_view: Dictionary) -> void:
	quest_title.text = str(map_view.get("quest_title", "Quest Map"))
	mode_label.text = str(map_view.get("mode_label", "Mode: -"))
	current_node_label.text = str(map_view.get("current_node_label", "Current Node: -"))
	summary_label.text = str(map_view.get("summary", "No state loaded yet."))
	groups_summary_label.text = str(map_view.get("group_summary", "No level groups available yet."))

	for child in groups_container.get_children():
		child.queue_free()
	for child in nodes_container.get_children():
		child.queue_free()

	var groups: Variant = map_view.get("groups", [])
	if groups is Array and not groups.is_empty():
		for group_view_variant in groups:
			if group_view_variant is Dictionary:
				_add_group_card(group_view_variant)
	else:
		var empty_group_label := Label.new()
		empty_group_label.text = "No level groups available yet."
		groups_container.add_child(empty_group_label)

	var show_legacy_nodes: bool = bool(map_view.get("show_legacy_nodes", false))
	nodes_title.visible = show_legacy_nodes
	nodes_container.visible = show_legacy_nodes
	if not show_legacy_nodes:
		return

	var nodes: Variant = map_view.get("nodes", [])
	if not (nodes is Array) or nodes.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No map nodes available yet."
		nodes_container.add_child(empty_label)
		return

	for node_view_variant in nodes:
		if not (node_view_variant is Dictionary):
			continue
		_add_node_card(node_view_variant)


func _add_group_card(group_view: Dictionary) -> void:
	var button := Button.new()
	button.custom_minimum_size = Vector2(220, 120)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var detail_lines: PackedStringArray = [
		str(group_view.get("title", "Group")),
		str(group_view.get("subtitle", "")),
		"[%s]" % str(group_view.get("status_label", "Unknown")),
	]
	var progress_label: String = str(group_view.get("progress_label", ""))
	if progress_label != "":
		detail_lines.append(progress_label)
	var current_label: String = str(group_view.get("current_label", ""))
	if current_label != "":
		detail_lines.append(current_label)
	button.text = "\n".join(detail_lines)
	button.disabled = not bool(group_view.get("is_enterable", false))

	var status_key: String = str(group_view.get("status_key", "locked"))
	match status_key:
		"current":
			button.modulate = Color(1.0, 0.93, 0.65)
		"completed":
			button.modulate = Color(0.72, 1.0, 0.78)
		"available":
			button.modulate = Color(0.76, 0.9, 1.0)
		_:
			button.modulate = Color(0.72, 0.72, 0.72)

	var group_id: String = str(group_view.get("group_id", ""))
	button.pressed.connect(func() -> void:
		group_pressed.emit(group_id)
	)
	groups_container.add_child(button)


func _add_node_card(node_view: Dictionary) -> void:
	var button := Button.new()
	button.custom_minimum_size = Vector2(220, 96)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.text = "%s\n%s\n[%s]" % [
		str(node_view.get("title", "Node")),
		str(node_view.get("node_type", "")),
		str(node_view.get("status_label", "Unknown")),
	]
	button.disabled = not bool(node_view.get("is_enterable", false))

	var status_key: String = str(node_view.get("status_key", "locked"))
	match status_key:
		"current":
			button.modulate = Color(1.0, 0.93, 0.65)
		"completed":
			button.modulate = Color(0.72, 1.0, 0.78)
		"available":
			button.modulate = Color(0.76, 0.9, 1.0)
		_:
			button.modulate = Color(0.72, 0.72, 0.72)

	var node_id: String = str(node_view.get("node_id", ""))
	button.pressed.connect(func() -> void:
		node_pressed.emit(node_id)
	)
	nodes_container.add_child(button)
