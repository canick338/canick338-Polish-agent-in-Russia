extends TextureRect

func _can_drop_data(at_position, data):
	return typeof(data) == TYPE_DICTIONARY and data.has("type") and data.type == "ingredient"

func _drop_data(at_position, data):
	# Call the main scene script
	if owner and owner.has_method("on_ingredient_dropped"):
		owner.on_ingredient_dropped(data.name)
