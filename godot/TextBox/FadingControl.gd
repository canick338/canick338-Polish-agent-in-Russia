## Uses a Tween object to animate the control node fading in and out.
extends Control

const COLOR_WHITE_TRANSPARENT := Color(1.0, 1.0, 1.0, 0.0)

@export var appear_duration := 0.3


func _ready() -> void:
	modulate = COLOR_WHITE_TRANSPARENT


func appear() -> void:
	var _tween = create_tween()
	# Проверяем, является ли родитель TextBox (компенсируем прозрачность 0.55)
	var parent_is_textbox = get_parent() != null and get_parent().get_parent() != null and get_parent().get_parent().name == "TextBox"
	var target_color = Color(1, 1, 1, 1.818) if parent_is_textbox else Color.WHITE
	
	_tween.tween_property(
		self, "modulate", target_color, appear_duration
	).from(COLOR_WHITE_TRANSPARENT)
	# Убедиться что после анимации всегда непрозрачный (с компенсацией если нужно)
	_tween.finished.connect(func(): modulate = target_color)


func disappear() -> void:
	var _tween = create_tween()
	_tween.tween_property(
		self, "modulate", COLOR_WHITE_TRANSPARENT, appear_duration / 2.0
	).from(Color.WHITE)
