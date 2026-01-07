extends Control

signal jar_clicked(jar)

var type: String = "empty"
var is_filled: bool = false
var has_sticker: bool = false

# Preload textures
# Caching variables
var tex_empty: Texture2D
var tex_filled: Texture2D

@onready var jar_sprite: TextureRect = $JarSprite
@onready var sticker_sprite: TextureRect = $StickerSprite
@onready var label: Label = $StickerSprite/JarLabel

func setup(jar_type: String):
	type = jar_type
	is_filled = false
	has_sticker = false
	
	# Determine if this jar starts filled (for variety) or empty
	# For this minigame logic, let's assume all come in empty and might get filled?
	# Or if the game spawns them mixed.
	# Based on current logic "label the jar", it implies we just stick labels.
	# But let's support filling visuals.
	
	_update_visuals()

func _update_visuals():
	if jar_sprite:
		if is_filled:
			if not tex_filled: tex_filled = load("res://Factory/Assets/jar_filled.png")
			jar_sprite.texture = tex_filled
		else:
			if not tex_empty: tex_empty = load("res://Factory/Assets/jar_empty.png")
			jar_sprite.texture = tex_empty
	
	if sticker_sprite:
		sticker_sprite.visible = has_sticker

func add_sticker(text: String):
	has_sticker = true
	if label:
		label.text = text
	_update_visuals()
	
	# Juiciness: Pop animation
	var tween = create_tween()
	scale = Vector2(1.2, 1.2)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BOUNCE)

func fill_jar():
	is_filled = true
	_update_visuals()

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		jar_clicked.emit(self)
