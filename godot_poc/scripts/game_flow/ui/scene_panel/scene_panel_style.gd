extends RefCounted
class_name ScenePanelStyle


static func apply_background(background_fallback: ColorRect, background_overlay: ColorRect, fallback_color: Color, overlay_color: Color) -> void:
	background_fallback.color = fallback_color
	background_overlay.color = overlay_color


static func apply_dialogue_panel(dialogue_panel: PanelContainer, dialogue_margin: MarginContainer, fill_color: Color, border_color: Color, border_width: int, corner_radius: int, shadow_color: Color, shadow_size: int, content_padding: Vector2i, min_height: int) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(corner_radius)
	style.shadow_color = shadow_color
	style.shadow_size = shadow_size
	dialogue_panel.add_theme_stylebox_override("panel", style)
	dialogue_panel.custom_minimum_size = Vector2(dialogue_panel.custom_minimum_size.x, min_height)
	dialogue_margin.add_theme_constant_override("margin_left", content_padding.x)
	dialogue_margin.add_theme_constant_override("margin_top", content_padding.y)
	dialogue_margin.add_theme_constant_override("margin_right", content_padding.x)
	dialogue_margin.add_theme_constant_override("margin_bottom", content_padding.y)


static func apply_nameplate(root: Control, frame: TextureRect, fallback: PanelContainer, min_size: Vector2, frame_texture: Texture2D, fill_color: Color, border_color: Color, border_width: int, corner_radius: int) -> void:
	root.custom_minimum_size = min_size
	root.size = min_size
	frame.texture = frame_texture
	frame.visible = frame_texture != null
	fallback.visible = frame_texture == null
	var style := StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(corner_radius)
	fallback.add_theme_stylebox_override("panel", style)


static func apply_text(dialogue_text: RichTextLabel, speaker_side_label: Label, continue_hint_label: Label, nameplate_labels: Array[Label], dialogue_text_min_height: int, dialogue_font_size: int, dialogue_text_color: Color, dialogue_line_separation: int, nameplate_font_size: int, nameplate_text_color: Color, meta_font_size: int, meta_text_color: Color, show_dialogue_meta: bool, continue_hint_font_size: int, continue_hint_color: Color) -> void:
	dialogue_text.custom_minimum_size = Vector2(0, dialogue_text_min_height)
	dialogue_text.add_theme_font_size_override("normal_font_size", dialogue_font_size)
	dialogue_text.add_theme_color_override("default_color", dialogue_text_color)
	dialogue_text.add_theme_constant_override("line_separation", dialogue_line_separation)
	for label in nameplate_labels:
		label.add_theme_font_size_override("font_size", nameplate_font_size)
		label.add_theme_color_override("font_color", nameplate_text_color)
	speaker_side_label.add_theme_font_size_override("font_size", meta_font_size)
	speaker_side_label.modulate = meta_text_color
	speaker_side_label.visible = show_dialogue_meta
	continue_hint_label.add_theme_font_size_override("font_size", continue_hint_font_size)
	continue_hint_label.modulate = continue_hint_color


static func apply_actor_placeholders(left_placeholder: Label, center_placeholder: Label, right_placeholder: Label, left_silhouette: ColorRect, center_silhouette: ColorRect, right_silhouette: ColorRect, left_color: Color, center_color: Color, right_color: Color, silhouette_color: Color) -> void:
	left_placeholder.modulate = left_color
	center_placeholder.modulate = center_color
	right_placeholder.modulate = right_color
	left_silhouette.color = silhouette_color
	center_silhouette.color = silhouette_color
	right_silhouette.color = silhouette_color


static func apply_decor(left_decor: TextureRect, right_decor: TextureRect, left_texture: Texture2D, right_texture: Texture2D) -> void:
	left_decor.texture = left_texture
	left_decor.visible = left_texture != null
	right_decor.texture = right_texture
	right_decor.visible = right_texture != null
