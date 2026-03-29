extends RefCounted
class_name ScenePanelActorCalibration


static func resolve_position_offset(actor: Dictionary, expression_position_offsets: Dictionary, portrait_position_offsets: Dictionary) -> Vector2:
	var expression_key := actor_expression_key(actor)
	var expression_offset := vector2_from_variant(expression_position_offsets.get(expression_key, null), Vector2.ZERO)
	if expression_offset != Vector2.ZERO:
		return expression_offset
	var portrait_id: String = str(actor.get("portrait_id", ""))
	return vector2_from_variant(portrait_position_offsets.get(portrait_id, null), Vector2.ZERO)


static func resolve_scale(actor: Dictionary, expression_scale_overrides: Dictionary, portrait_scale_overrides: Dictionary) -> Vector2:
	var expression_key := actor_expression_key(actor)
	var expression_scale := scale_from_variant(expression_scale_overrides.get(expression_key, null), Vector2.ONE)
	if expression_scale != Vector2.ONE:
		return expression_scale
	var portrait_id: String = str(actor.get("portrait_id", ""))
	return scale_from_variant(portrait_scale_overrides.get(portrait_id, null), Vector2.ONE)


static func actor_expression_key(actor: Dictionary) -> String:
	var portrait_id: String = str(actor.get("portrait_id", ""))
	var expression_id: String = str(actor.get("expression_id", ""))
	if portrait_id == "" or expression_id == "":
		return ""
	return "%s:%s" % [portrait_id, expression_id]


static func vector2_from_variant(value: Variant, fallback: Vector2) -> Vector2:
	if value is Vector2:
		return value
	if value is Array and value.size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	return fallback


static func scale_from_variant(value: Variant, fallback: Vector2) -> Vector2:
	if value is Vector2:
		return value
	if value is float or value is int:
		var scalar := float(value)
		return Vector2(scalar, scalar)
	if value is Array and value.size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	return fallback
