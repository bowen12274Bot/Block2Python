extends RefCounted
class_name QuestMapGroupCardBinding

const QuestMapGroupCatalogScript = preload("res://scripts/map/catalog/quest_map_group_catalog.gd")


static func collect(screen: Control, on_group_pressed: Callable) -> Dictionary:
	var group_cards: Dictionary = {}
	for group_id in QuestMapGroupCatalogScript.group_ids():
		var base_name: String = QuestMapGroupCatalogScript.scene_group_name(group_id)
		var root: Button = screen.get_node_or_null("StageFrame/HotspotLayer/%s" % base_name)
		if root == null:
			continue

		_bind_group_button(root, group_id, on_group_pressed)
		var lock_icon: TextureRect = screen.get_node_or_null("StageFrame/HotspotLayer/%s/LockIcon" % base_name)
		var art_rect: TextureRect = screen.get_node_or_null("StageFrame/HotspotLayer/%s/Art" % base_name)
		var art_placeholder: Label = screen.get_node_or_null("StageFrame/HotspotLayer/%s/ArtPlaceholder" % base_name)
		var nameplate: Node = screen.get_node_or_null("StageFrame/NameplateLayer/%s" % QuestMapGroupCatalogScript.scene_nameplate_name(group_id))

		for node in [lock_icon, art_rect, art_placeholder, nameplate]:
			if node != null:
				node.mouse_filter = Control.MOUSE_FILTER_IGNORE

		group_cards[group_id] = {
			"group_id": group_id,
			"root": root,
			"lock_icon": lock_icon,
			"art": art_rect,
			"art_placeholder": art_placeholder,
			"nameplate": nameplate,
		}
	return group_cards


static func _bind_group_button(root: Button, group_id: String, on_group_pressed: Callable) -> void:
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.focus_mode = Control.FOCUS_NONE
	root.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	root.pressed.connect(func() -> void:
		on_group_pressed.call(group_id)
	)


