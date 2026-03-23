extends RefCounted
class_name WindowAlignmentHelper

static func build_control_client_rect(control: Control, padding: Rect2i = Rect2i(0, 0, 0, 0)) -> Dictionary:
	if control == null:
		return _empty_rect()

	var viewport := control.get_viewport()
	if viewport == null:
		return _empty_rect()

	var global_rect: Rect2 = control.get_global_rect()
	var client_size: Vector2 = Vector2(DisplayServer.window_get_size())
	var viewport_size: Vector2 = viewport.get_visible_rect().size
	var scale_x: float = client_size.x / viewport_size.x if viewport_size.x > 0.0 else 1.0
	var scale_y: float = client_size.y / viewport_size.y if viewport_size.y > 0.0 else 1.0
	var uniform_scale: float = min(scale_x, scale_y)
	var used_size: Vector2 = viewport_size * uniform_scale
	var offset: Vector2 = (client_size - used_size) / 2.0
	var padding_left: int = padding.position.x
	var padding_top: int = padding.position.y
	var padding_right: int = padding.size.x
	var padding_bottom: int = padding.size.y
	var sx: int = int(round(offset.x + global_rect.position.x * uniform_scale)) + padding_left
	var sy: int = int(round(offset.y + global_rect.position.y * uniform_scale)) + padding_top
	var sw: int = maxi(int(round(global_rect.size.x * uniform_scale)) - padding_left - padding_right, 1)
	var sh: int = maxi(int(round(global_rect.size.y * uniform_scale)) - padding_top - padding_bottom, 1)
	return {
		"x": sx,
		"y": sy,
		"width": sw,
		"height": sh,
		"screen_x": sx,
		"screen_y": sy,
		"screen_width": sw,
		"screen_height": sh,
		"visible": control.is_visible_in_tree() and control.visible,
	}

static func build_layout_payload(level_id: String, owner_title: String, owner_hwnd: int, control: Control, visible: bool, padding: Rect2i = Rect2i(0, 0, 0, 0)) -> Dictionary:
	var rect: Dictionary = build_control_client_rect(control, padding)
	return {
		"level_id": level_id,
		"owner_title": owner_title,
		"owner_hwnd": owner_hwnd,
		"relative_x": int(rect.get("x", 0)),
		"relative_y": int(rect.get("y", 0)),
		"width": int(rect.get("width", 1)),
		"height": int(rect.get("height", 1)),
		"screen_x": int(rect.get("screen_x", rect.get("x", 0))),
		"screen_y": int(rect.get("screen_y", rect.get("y", 0))),
		"screen_width": int(rect.get("screen_width", rect.get("width", 1))),
		"screen_height": int(rect.get("screen_height", rect.get("height", 1))),
		"visible": bool(rect.get("visible", false)) and visible,
	}

static func _empty_rect() -> Dictionary:
	return {
		"x": 0,
		"y": 0,
		"width": 1,
		"height": 1,
		"screen_x": 0,
		"screen_y": 0,
		"screen_width": 1,
		"screen_height": 1,
		"visible": false,
	}
