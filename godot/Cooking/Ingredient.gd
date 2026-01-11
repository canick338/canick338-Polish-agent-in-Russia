extends TextureRect

@export var ingredient_name: String = "Ingredient"
@export var icon_texture: Texture2D

func _ready():
	if icon_texture:
		texture = icon_texture
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	custom_minimum_size = Vector2(80, 80)
	tooltip_text = ingredient_name

func _get_drag_data(at_position):
	var preview = TextureRect.new()
	preview.texture = texture
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.size = Vector2(60, 60)
	preview.modulate.a = 0.8
	
	# Центрируем превью
	var c = Control.new()
	c.add_child(preview)
	preview.position = -0.5 * preview.size
	set_drag_preview(c)
	
	return { "type": "ingredient", "name": ingredient_name }
