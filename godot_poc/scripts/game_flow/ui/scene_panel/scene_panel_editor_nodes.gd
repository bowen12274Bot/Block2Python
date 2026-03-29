extends RefCounted
class_name ScenePanelEditorNodes


static func ensure_calibration_stack_root(character_layer: Control, existing_root: Control) -> Control:
	if existing_root != null:
		return existing_root
	var calibration_root := Control.new()
	calibration_root.name = "EditorCalibrationStack"
	calibration_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	calibration_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	character_layer.add_child(calibration_root)
	for node_name in ["BytePreview", "SystemPreview", "PlayerFemalePreview", "PlayerMalePreview", "BugKingPreview"]:
		var preview_node := TextureRect.new()
		preview_node.name = node_name
		preview_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		preview_node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview_node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		calibration_root.add_child(preview_node)
	return calibration_root


static func ensure_preview_actor_nodes(existing_nodes: Dictionary, actor_roots: Dictionary) -> Dictionary:
	if not existing_nodes.is_empty():
		return existing_nodes
	var preview_nodes: Dictionary = {}
	for side in ["left", "center", "right"]:
		var source_root: Control = actor_roots.get(side)
		var parent_node: Node = source_root.get_parent()
		var preview_root := source_root.duplicate() as Control
		preview_root.name = "EditorPreview%sActorRoot" % side.capitalize()
		preview_root.owner = null
		parent_node.add_child(preview_root)
		preview_nodes[side] = {
			"root": preview_root,
			"texture": preview_root.get_node("ActorTexture") as TextureRect,
			"placeholder": preview_root.get_node("PlaceholderLabel") as Label,
			"silhouette": preview_root.get_node("SilhouetteOverlay") as ColorRect,
		}
	for side in actor_roots.keys():
		var actor_root: Control = actor_roots.get(side)
		actor_root.visible = false
	return preview_nodes


static func actor_nodes(side: String, existing_nodes: Dictionary, fallback_nodes: Dictionary) -> Dictionary:
	if existing_nodes.has(side):
		return existing_nodes[side]
	return fallback_nodes.get(side, {})
