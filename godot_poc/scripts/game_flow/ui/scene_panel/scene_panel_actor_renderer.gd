extends RefCounted
class_name ScenePanelActorRenderer


static func apply_background_view(background_value: Variant, background_texture: TextureRect, background_fallback: ColorRect, background_texture_paths: Dictionary, default_background_texture: Texture2D) -> void:
	var background: Dictionary = background_value if background_value is Dictionary else {}
	var texture := ScenePanelAssetResolver.resolve_background_texture(background, background_texture_paths, default_background_texture)
	background_texture.texture = texture
	background_texture.visible = texture != null
	background_fallback.visible = texture == null


static func apply_actor_view(actor_value: Variant, actor_root: Control, actor_texture: TextureRect, placeholder: Label, silhouette: ColorRect, side: String, base_position: Vector2, base_scale: Vector2, expression_position_offsets: Dictionary, portrait_position_offsets: Dictionary, expression_scale_overrides: Dictionary, portrait_scale_overrides: Dictionary, expression_texture_paths: Dictionary, portrait_texture_paths: Dictionary, default_left_actor_texture: Texture2D, default_center_actor_texture: Texture2D, default_right_actor_texture: Texture2D, flip_left_actor: bool, flip_center_actor: bool, flip_right_actor: bool, actor_focus_scale: Vector2, actor_dim_alpha: float, actor_silhouette_alpha: float, actor_hidden_alpha: float) -> void:
	var actor: Dictionary = actor_value if actor_value is Dictionary else {}
	var visual_state: String = str(actor.get("visual_state", "hidden"))
	var texture := ScenePanelAssetResolver.resolve_actor_texture(actor, side, expression_texture_paths, portrait_texture_paths, default_left_actor_texture, default_center_actor_texture, default_right_actor_texture)
	var display_name: String = str(actor.get("display_name", ""))
	var actor_offset: Vector2 = ScenePanelActorCalibration.resolve_position_offset(actor, expression_position_offsets, portrait_position_offsets)
	var calibrated_scale: Vector2 = ScenePanelActorCalibration.resolve_scale(actor, expression_scale_overrides, portrait_scale_overrides) * base_scale
	if display_name == "":
		display_name = side.capitalize()
	actor_root.position = base_position + actor_offset
	actor_texture.texture = texture
	actor_texture.flip_h = ScenePanelAssetResolver.is_actor_flipped(side, flip_left_actor, flip_center_actor, flip_right_actor)
	placeholder.text = display_name
	placeholder.visible = texture == null and visual_state != "hidden"
	actor_texture.visible = texture != null and visual_state != "hidden"
	silhouette.visible = visual_state == "silhouette"
	match visual_state:
		"focus":
			actor_root.visible = true
			actor_root.modulate = Color(1, 1, 1, 1)
			actor_root.scale = Vector2(calibrated_scale.x * actor_focus_scale.x, calibrated_scale.y * actor_focus_scale.y)
			placeholder.modulate.a = 0.92
		"dim":
			actor_root.visible = true
			actor_root.modulate = Color(1, 1, 1, actor_dim_alpha)
			actor_root.scale = calibrated_scale
			placeholder.modulate.a = actor_dim_alpha
		"silhouette":
			actor_root.visible = true
			actor_root.modulate = Color(1, 1, 1, actor_silhouette_alpha)
			actor_root.scale = calibrated_scale
			placeholder.modulate.a = actor_silhouette_alpha
		"hidden":
			actor_root.visible = false
			actor_root.modulate = Color(1, 1, 1, actor_hidden_alpha)
			actor_root.scale = calibrated_scale
			placeholder.modulate.a = 0.0
		_:
			actor_root.visible = true
			actor_root.modulate = Color(1, 1, 1, 1)
			actor_root.scale = calibrated_scale
			placeholder.modulate.a = 0.88
