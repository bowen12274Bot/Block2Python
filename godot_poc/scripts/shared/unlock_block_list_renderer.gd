extends RefCounted
class_name UnlockBlockListRenderer


static func render(container: HFlowContainer, blocks_variant: Variant, options: Dictionary = {}) -> void:
	if container == null:
		return
	for child in container.get_children():
		child.queue_free()

	var blocks: Array[Dictionary] = _block_dict_array(blocks_variant)
	if blocks.is_empty():
		var empty_label := Label.new()
		empty_label.text = str(options.get("empty_text", "No new blocks yet."))
		var empty_modulate: Variant = options.get("empty_modulate", null)
		if empty_modulate is Color:
			empty_label.modulate = empty_modulate
		container.add_child(empty_label)
		return

	for block_view in blocks:
		container.add_child(_build_card(block_view, options))


static func _block_dict_array(value: Variant) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	if value is Array:
		for item in value:
			if item is Dictionary:
				results.append(item)
	return results


static func _build_card(block_view: Dictionary, options: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = options.get("card_minimum_size", Vector2(160, 92))
	var card_modulate: Variant = options.get("card_modulate", null)
	if card_modulate is Color:
		card.modulate = card_modulate

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", int(options.get("margin_left", 10)))
	margin.add_theme_constant_override("margin_top", int(options.get("margin_top", 10)))
	margin.add_theme_constant_override("margin_right", int(options.get("margin_right", 10)))
	margin.add_theme_constant_override("margin_bottom", int(options.get("margin_bottom", 10)))
	card.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", int(options.get("column_separation", 6)))
	margin.add_child(column)

	var title_label := Label.new()
	title_label.text = str(block_view.get("title", "Block"))
	title_label.add_theme_font_size_override("font_size", int(options.get("title_font_size", 18)))
	var title_modulate: Variant = options.get("title_modulate", null)
	if title_modulate is Color:
		title_label.modulate = title_modulate
	column.add_child(title_label)

	var body_label := Label.new()
	body_label.text = str(block_view.get("description", ""))
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.add_theme_font_size_override("font_size", int(options.get("body_font_size", 14)))
	var body_modulate: Variant = options.get("body_modulate", null)
	if body_modulate is Color:
		body_label.modulate = body_modulate
	column.add_child(body_label)

	return card
