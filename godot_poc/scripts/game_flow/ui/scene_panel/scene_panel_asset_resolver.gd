extends RefCounted
class_name ScenePanelAssetResolver


static func resolve_background_texture(background: Dictionary, background_texture_paths: Dictionary, default_background_texture: Texture2D) -> Texture2D:
	var image_path: String = str(background.get("image_path", ""))
	if image_path != "":
		var direct_texture := load_texture(image_path)
		if direct_texture != null:
			return direct_texture
	return texture_from_mapping(background_texture_paths, str(background.get("background_id", "")), default_background_texture)


static func resolve_actor_texture(actor: Dictionary, side: String, expression_texture_paths: Dictionary, portrait_texture_paths: Dictionary, default_left_actor_texture: Texture2D, default_center_actor_texture: Texture2D, default_right_actor_texture: Texture2D) -> Texture2D:
	var image_path: String = str(actor.get("image_path", ""))
	if image_path != "":
		var direct_texture := load_texture(image_path)
		if direct_texture != null:
			return direct_texture
	var portrait_id: String = str(actor.get("portrait_id", ""))
	var expression_id: String = str(actor.get("expression_id", ""))
	if portrait_id != "" and expression_id != "":
		var expression_key := "%s:%s" % [portrait_id, expression_id]
		var expression_texture := texture_from_mapping(expression_texture_paths, expression_key, null)
		if expression_texture != null:
			return expression_texture
	var fallback_texture: Texture2D = default_actor_texture_for_side(side, default_left_actor_texture, default_center_actor_texture, default_right_actor_texture)
	return texture_from_mapping(portrait_texture_paths, portrait_id, fallback_texture)


static func default_actor_texture_for_side(side: String, default_left_actor_texture: Texture2D, default_center_actor_texture: Texture2D, default_right_actor_texture: Texture2D) -> Texture2D:
	match side:
		"center":
			return default_center_actor_texture
		"right":
			return default_right_actor_texture
		_:
			return default_left_actor_texture


static func is_actor_flipped(side: String, flip_left_actor: bool, flip_center_actor: bool, flip_right_actor: bool) -> bool:
	match side:
		"center":
			return flip_center_actor
		"right":
			return flip_right_actor
		_:
			return flip_left_actor


static func texture_from_mapping(mapping: Dictionary, key: String, fallback: Texture2D) -> Texture2D:
	if key != "" and mapping.has(key):
		var value: Variant = mapping[key]
		if value is Texture2D:
			return value
		if value is String:
			var mapped_texture := load_texture(str(value))
			if mapped_texture != null:
				return mapped_texture
	return fallback


static func load_texture(resource_path: String) -> Texture2D:
	if resource_path == "":
		return null
	if not ResourceLoader.exists(resource_path):
		return null
	var resource := ResourceLoader.load(resource_path)
	return resource as Texture2D
