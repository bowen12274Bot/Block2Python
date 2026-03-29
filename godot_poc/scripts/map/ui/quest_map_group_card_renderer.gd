extends RefCounted
class_name QuestMapGroupCardRenderer

const QuestMapGroupCatalogScript = preload("res://scripts/map/catalog/quest_map_group_catalog.gd")


static func apply_group_card(card_view: Dictionary, group_view: Dictionary) -> void:
	var root: Button = card_view.get("root", null)
	if root == null:
		return
	var nameplate: Node = card_view.get("nameplate", null)
	if group_view.is_empty():
		root.visible = false
		if nameplate != null:
			nameplate.visible = false
		return

	var group_id: String = str(group_view.get("group_id", str(card_view.get("group_id", ""))))
	var lock_icon: TextureRect = card_view.get("lock_icon", null)
	var art_rect: TextureRect = card_view.get("art", null)
	var art_placeholder: Label = card_view.get("art_placeholder", null)

	root.visible = true
	if nameplate != null:
		nameplate.visible = true

	var group_art: Texture2D = _load_group_art(group_id)
	if art_rect != null:
		art_rect.texture = group_art
		art_rect.modulate = Color(1, 1, 1, 1) if bool(group_view.get("is_enterable", false)) else Color(0.72, 0.72, 0.72, 0.92)
	if art_placeholder != null:
		art_placeholder.visible = group_art == null
		art_placeholder.text = "Drop art\n%s" % QuestMapGroupCatalogScript.art_path_for_group(group_id)

	var fallback_title: String = str(group_view.get("theme_title", group_view.get("title", "Stage")))
	var stage_title: String = QuestMapGroupCatalogScript.display_title_for_group(group_id, fallback_title)
	if nameplate != null:
		if nameplate.has_method("set_stage_number_text"):
			nameplate.call("set_stage_number_text", _stage_number_text(group_id))
		if nameplate.has_method("set_stage_title_text"):
			nameplate.call("set_stage_title_text", stage_title)
	if lock_icon != null:
		lock_icon.visible = str(group_view.get("status_key", "locked")) == "locked"

	_apply_card_styles(root)


static func _load_group_art(group_id: String) -> Texture2D:
	var path: String = QuestMapGroupCatalogScript.art_path_for_group(group_id)
	if path == "" or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


static func _stage_number_text(group_id: String) -> String:
	var parts := group_id.split("-")
	if parts.size() < 2:
		return group_id
	return parts[1]


static func _apply_card_styles(root: Button) -> void:
	var normal_style := _card_style()
	var hover_style := _card_hover_style()
	root.add_theme_stylebox_override("normal", normal_style)
	root.add_theme_stylebox_override("hover", hover_style)
	root.add_theme_stylebox_override("pressed", hover_style)
	root.add_theme_stylebox_override("focus", hover_style)
	root.add_theme_stylebox_override("disabled", normal_style)


static func _card_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.corner_radius_top_left = 24
	style.corner_radius_top_right = 24
	style.corner_radius_bottom_right = 24
	style.corner_radius_bottom_left = 24
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
	style.shadow_size = 6
	style.bg_color = Color(1, 1, 1, 0.02)
	style.border_color = Color(1, 1, 1, 0.30)
	return style


static func _card_hover_style() -> StyleBoxFlat:
	var style := _card_style()
	style.bg_color = Color(1, 1, 1, 0.08)
	style.border_color = Color(1, 1, 1, 0.52)
	style.shadow_size = 10
	return style

