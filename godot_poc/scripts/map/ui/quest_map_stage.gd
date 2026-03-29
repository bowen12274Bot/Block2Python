extends Control
class_name QuestMapStage

const QuestMapRouteCatalogScript = preload("res://scripts/map/catalog/quest_map_route_catalog.gd")

@onready var header_row: HBoxContainer = get_node_or_null("HudLayer/Header")
@onready var header_title_column: VBoxContainer = get_node_or_null("HudLayer/Header/TitleColumn")
@onready var header_title: Label = get_node_or_null("HudLayer/Header/TitleColumn/Title")
@onready var header_subtitle: Label = get_node_or_null("HudLayer/Header/TitleColumn/Subtitle")
@onready var background_hint: Label = get_node_or_null("BackgroundTexture/BackgroundHint")
@onready var route_layer: Control = get_node_or_null("RouteLayer")
@onready var route_anchor_layer: Control = get_node_or_null("RouteLayer/RouteAnchors")
@onready var foreground_hint: Label = get_node_or_null("ForegroundTexture/ForegroundHint")

var _last_map_view: Dictionary = {}
var _helper_text_override: String = ""
var _route_nodes: Array[Node] = []


func _ready() -> void:
	if route_layer != null:
		route_layer.z_index = 1
	if header_row != null:
		header_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		header_row.visible = true
	if header_title_column != null:
		header_title_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if header_title != null:
		header_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if header_subtitle != null:
		header_subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if background_hint != null:
		background_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
		background_hint.visible = false
		background_hint.text = "Drop final starfield / map base art here"
	if foreground_hint != null:
		foreground_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
		foreground_hint.visible = false
		foreground_hint.text = "Optional foreground VFX / clouds / frame art"
	if route_anchor_layer != null and not Engine.is_editor_hint():
		route_anchor_layer.visible = false
	_refresh_header()


func show_map(map_view: Dictionary) -> void:
	_last_map_view = map_view.duplicate(true)
	_refresh_header()
	_render_route_lines(map_view)


func set_helper_text(text: String) -> void:
	_helper_text_override = text
	_refresh_header()


func _refresh_header() -> void:
	if header_title != null:
		header_title.text = str(_last_map_view.get("quest_title", "Quest Map"))
	if header_subtitle != null:
		var subtitle_text: String = _helper_text_override.strip_edges()
		if subtitle_text == "":
			subtitle_text = str(_last_map_view.get("summary", "Main map is waiting for route data."))
		header_subtitle.text = subtitle_text


func _render_route_lines(map_view: Dictionary) -> void:
	_clear_route_nodes()
	if route_layer == null or route_anchor_layer == null:
		return
	var group_lookup := _group_lookup(map_view)
	for segment in QuestMapRouteCatalogScript.route_segments():
		var start_point := _anchor_center(str(segment.get("start", "")))
		var control_point := _anchor_center(str(segment.get("control", "")))
		var end_point := _anchor_center(str(segment.get("end", "")))
		if start_point == Vector2.ZERO or control_point == Vector2.ZERO or end_point == Vector2.ZERO:
			continue
		var points := _quadratic_curve_points(start_point, control_point, end_point)
		var status_key := _segment_status_key(group_lookup.get(str(segment.get("to_group", "")), {}))
		_add_route_segment(points, status_key)


func _clear_route_nodes() -> void:
	for node in _route_nodes:
		if is_instance_valid(node):
			node.queue_free()
	_route_nodes.clear()


func _group_lookup(map_view: Dictionary) -> Dictionary:
	var lookup: Dictionary = {}
	var groups_variant: Variant = map_view.get("groups", [])
	if groups_variant is Array:
		for group_variant in groups_variant:
			if group_variant is Dictionary:
				var group_view: Dictionary = group_variant
				lookup[str(group_view.get("group_id", ""))] = group_view
	return lookup


func _anchor_center(node_name: String) -> Vector2:
	if route_anchor_layer == null or node_name == "":
		return Vector2.ZERO
	var anchor: Control = route_anchor_layer.get_node_or_null(node_name)
	if anchor == null:
		return Vector2.ZERO
	return anchor.position + anchor.size * 0.5


func _quadratic_curve_points(start_point: Vector2, control_point: Vector2, end_point: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	var steps := 30
	for step in range(steps + 1):
		var t := float(step) / float(steps)
		var u := 1.0 - t
		points.append(u * u * start_point + 2.0 * u * t * control_point + t * t * end_point)
	return points


func _segment_status_key(group_view_variant: Variant) -> String:
	if group_view_variant is Dictionary:
		return str(group_view_variant.get("status_key", "locked"))
	return "locked"


func _add_route_segment(points: PackedVector2Array, status_key: String) -> void:
	var brightness: float = QuestMapRouteCatalogScript.brightness_for_status(status_key)
	var glow := Line2D.new()
	glow.points = points
	glow.width = 16.0
	glow.default_color = Color(0.55, 0.95, 1.0, 0.13 + brightness * 0.18)
	glow.begin_cap_mode = Line2D.LINE_CAP_ROUND
	glow.end_cap_mode = Line2D.LINE_CAP_ROUND
	glow.joint_mode = Line2D.LINE_JOINT_ROUND
	glow.antialiased = true
	glow.z_index = 0
	route_layer.add_child(glow)
	_route_nodes.append(glow)

	var core := Line2D.new()
	core.points = points
	core.width = 5.0
	core.default_color = Color(0.82, 0.98, 1.0, 0.30 + brightness * 0.46)
	core.begin_cap_mode = Line2D.LINE_CAP_ROUND
	core.end_cap_mode = Line2D.LINE_CAP_ROUND
	core.joint_mode = Line2D.LINE_JOINT_ROUND
	core.antialiased = true
	core.z_index = 1
	route_layer.add_child(core)
	_route_nodes.append(core)

	var orb := ColorRect.new()
	orb.color = Color(0.88, 1.0, 0.98, 0.24 + brightness * 0.32)
	orb.custom_minimum_size = Vector2(10, 10)
	orb.size = Vector2(10, 10)
	orb.position = points[points.size() - 1] - Vector2(5, 5)
	orb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	orb.z_index = 2
	route_layer.add_child(orb)
	_route_nodes.append(orb)

