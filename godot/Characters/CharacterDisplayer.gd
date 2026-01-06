## Displays and animates [Character] portraits, for example, entering from the left or the right.
## Place it behind a [TextBox].
class_name CharacterDisplayer
extends Node

## Emitted when the characters finished displaying or finished their animation.
signal display_finished

## Maps animation text ids to a function that animates a character sprite.
const ANIMATIONS := {"enter": "_enter", "leave": "_leave"}
const SIDE_LEFT := "left"
const SIDE_RIGHT := "right"
const COLOR_WHITE_TRANSPARENT = Color(1.0, 1.0, 1.0, 0.0)

## Keeps track of the character displayed on either side.
var _left_character: Character = null
var _right_character: Character = null

var _tween: Tween
@onready var _left_sprite: Sprite2D = $Left
@onready var _right_sprite: Sprite2D = $Right


func _ready() -> void:
	_left_sprite.hide()
	_right_sprite.hide()


func _unhandled_input(event: InputEvent) -> void:
	# If the player presses enter before the character animations ended, we seek to the end.
	if event.is_action_pressed("ui_accept") and _tween and _tween.is_running():
		_tween.custom_step(100.0)
		_tween.kill()


func display(character: Character, side: String = SIDE_LEFT, expression := "", animation := "") -> void:
	# Проверка на null персонажа
	if not character:
		push_error("CharacterDisplayer.display: character is null")
		return
	
	# Keeps track of a character that's already displayed on a given side
	var sprite: Sprite2D = _left_sprite if side == SIDE_LEFT else _right_sprite
	
	# Проверка какой персонаж уже отображается
	if side == SIDE_LEFT:
		if character != _left_character:
			_left_character = character
	else:
		if character != _right_character:
			_right_character = character

	# Использовать статичное изображение
	var texture = character.get_image(expression)
	if texture:
		sprite.texture = texture
		sprite.show()
	else:
		push_error("CharacterDisplayer.display: texture is null for expression: " + expression)
		sprite.hide()

	if animation != "" and ANIMATIONS.has(animation):
		call(ANIMATIONS[animation], side, sprite)


## Fades in and moves the character to the anchor position.
func _enter(from_side: String, node: Node) -> void:
	var offset := -200 if from_side == SIDE_LEFT else 200
	
	if node is Sprite2D:
		var sprite := node as Sprite2D
		var start = sprite.position + Vector2(offset, 0.0)
		var end = sprite.position
		
		_tween = create_tween()
		_tween.finished.connect(_on_tween_finished)
		_tween.set_parallel(true)
		_tween.tween_property(
			sprite, "position", end, 0.5
		).from(start).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
		_tween.tween_property(sprite, "modulate", Color.WHITE, 0.25).from(COLOR_WHITE_TRANSPARENT)
		
		sprite.position = start
		sprite.modulate = COLOR_WHITE_TRANSPARENT


func _leave(from_side: String, node: Node) -> void:
	var offset := -200 if from_side == SIDE_LEFT else 200
	
	if node is Sprite2D:
		var sprite := node as Sprite2D
		var start := sprite.position
		var end := sprite.position + Vector2(offset, 0.0)

		_tween = create_tween()
		_tween.finished.connect(_on_tween_finished)
		_tween.set_parallel(true)
		_tween.tween_property(
			sprite, "position", end, 0.5
		).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT).from(start)
		_tween.tween_property(
			sprite,
			"modulate",
			COLOR_WHITE_TRANSPARENT,
			0.25,
		).set_delay(.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_LINEAR).from(Color.WHITE)
		_tween.start()
		_tween.seek(0.0)


func _on_tween_finished() -> void:
	display_finished.emit()
