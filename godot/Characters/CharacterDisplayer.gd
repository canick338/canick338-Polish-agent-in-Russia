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

## Храним оригинальные позиции и масштабы для эффектов
var _left_original_position: Vector2
var _right_original_position: Vector2
var _left_original_scale: Vector2
var _right_original_scale: Vector2

## Tween'ы для эффектов (массив для хранения всех tween'ов)
var _left_idle_tweens: Array[Tween] = []
var _right_idle_tweens: Array[Tween] = []


func _ready() -> void:
	_left_sprite.hide()
	_right_sprite.hide()
	# Сохраняем оригинальные позиции и масштабы
	_left_original_position = _left_sprite.position
	_right_original_position = _right_sprite.position
	_left_original_scale = _left_sprite.scale
	_right_original_scale = _right_sprite.scale


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
	
	# Определяем какой спрайт использовать
	var sprite: Sprite2D = _left_sprite if side == SIDE_LEFT else _right_sprite
	
	# Использовать статичное изображение
	var texture = character.get_image(expression)
	
	# Проверяем, меняется ли персонаж или эмоция (ДО обновления персонажа и текстуры)
	var is_new_character := false
	var is_expression_change := false
	var previous_texture = sprite.texture
	
	if side == SIDE_LEFT:
		is_new_character = (_left_character != character)
		# Проверяем изменение эмоции: либо новый персонаж, либо та же текстура изменилась
		is_expression_change = (is_new_character or (_left_character == character and previous_texture != texture and previous_texture != null))
	else:
		is_new_character = (_right_character != character)
		is_expression_change = (is_new_character or (_right_character == character and previous_texture != texture and previous_texture != null))
	
	# Проверяем, переходит ли персонаж с одной стороны на другую
	var is_side_change := false
	var previous_side := ""
	
	if side == SIDE_LEFT:
		# Если этот персонаж был справа - это переход!
		if _right_character == character:
			is_side_change = true
			previous_side = SIDE_RIGHT
			_stop_idle_effects(SIDE_RIGHT)
		# Обновляем персонажа слева
		_left_character = character
		# ВАЖНО: НЕ трогаем правого персонажа - он должен оставаться видимым!
	else:
		# Если этот персонаж был слева - это переход!
		if _left_character == character:
			is_side_change = true
			previous_side = SIDE_LEFT
			_stop_idle_effects(SIDE_LEFT)
		# Обновляем персонажа справа
		_right_character = character
		# ВАЖНО: НЕ трогаем левого персонажа - он должен оставаться видимым!
	
	if texture:
		# Останавливаем предыдущие idle эффекты перед применением новых
		if is_expression_change:
			_stop_idle_effects(side)
		
		# Если это переход между сторонами - делаем плавную анимацию
		if is_side_change:
			_transition_character_to_side(character, previous_side, side, texture, expression)
		else:
			# Обычное отображение
			sprite.texture = texture
			sprite.show()
			# ВАЖНО: Не скрываем другой спрайт - он должен оставаться видимым!
			
			# Эффект при смене диалога/эмоции (применяем ПЕРЕД idle эффектами)
			if is_expression_change or is_new_character:
				_play_dialogue_change_effect(sprite, side, expression, is_new_character)
				# Запускаем idle эффекты с небольшой задержкой через Timer
				var delay_timer := Timer.new()
				delay_timer.wait_time = 0.25  # Задержка 0.25 сек
				delay_timer.one_shot = true
				add_child(delay_timer)
				delay_timer.timeout.connect(func():
					_start_idle_effects(sprite, side, expression)
					delay_timer.queue_free()
				)
				delay_timer.start()
			else:
				# Запускаем эффекты "живости" для персонажа сразу
				_start_idle_effects(sprite, side, expression)
	else:
		push_error("CharacterDisplayer.display: texture is null for expression: " + expression)
		sprite.hide()
		_stop_idle_effects(side)

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


## ============================================
## ПЛАВНЫЕ ПЕРЕХОДЫ МЕЖДУ СТОРОНАМИ
## ============================================

func _transition_character_to_side(character: Character, from_side: String, to_side: String, texture: Texture2D, expression: String) -> void:
	"""Плавный переход персонажа с одной стороны на другую"""
	var from_sprite: Sprite2D = _left_sprite if from_side == SIDE_LEFT else _right_sprite
	var to_sprite: Sprite2D = _left_sprite if to_side == SIDE_LEFT else _right_sprite
	
	var from_pos: Vector2 = _left_original_position if from_side == SIDE_LEFT else _right_original_position
	var to_pos: Vector2 = _left_original_position if to_side == SIDE_LEFT else _right_original_position
	
	# Устанавливаем текстуру на новом спрайте
	to_sprite.texture = texture
	to_sprite.scale = from_sprite.scale  # Сохраняем масштаб
	to_sprite.modulate = from_sprite.modulate  # Сохраняем прозрачность
	
	# Начальная позиция для нового спрайта (с противоположной стороны)
	var start_offset := 300.0 if to_side == SIDE_LEFT else -300.0
	var start_pos := to_pos + Vector2(start_offset, 0)
	
	# Позиционируем новый спрайт в начальной позиции
	to_sprite.position = start_pos
	to_sprite.show()
	
	# Создаем плавный переход
	var transition_tween := create_tween()
	transition_tween.set_parallel(true)
	
	# Анимация движения
	transition_tween.tween_property(
		to_sprite, "position",
		to_pos,
		0.6  # Плавный переход 0.6 сек
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	
	# Анимация появления (fade in)
	to_sprite.modulate = COLOR_WHITE_TRANSPARENT
	transition_tween.tween_property(
		to_sprite, "modulate",
		Color.WHITE,
		0.4
	).set_ease(Tween.EASE_IN_OUT)
	
	# Одновременно скрываем старый спрайт
	var fade_out_tween := create_tween()
	fade_out_tween.set_parallel(true)
	
	# Fade out старого спрайта
	fade_out_tween.tween_property(
		from_sprite, "modulate",
		COLOR_WHITE_TRANSPARENT,
		0.3
	).set_ease(Tween.EASE_IN_OUT)
	
	# Движение старого спрайта в сторону (опционально, для красоты)
	var old_end_offset := -200.0 if from_side == SIDE_LEFT else 200.0
	fade_out_tween.tween_property(
		from_sprite, "position",
		from_pos + Vector2(old_end_offset, 0),
		0.4
	).set_ease(Tween.EASE_IN_OUT)
	
	# Скрываем старый спрайт после анимации
	fade_out_tween.finished.connect(func():
		from_sprite.hide()
		from_sprite.position = from_pos  # Возвращаем в исходную позицию
		from_sprite.modulate = Color.WHITE  # Возвращаем прозрачность
	)
	
	# После завершения перехода запускаем idle эффекты
	transition_tween.finished.connect(func():
		# Эффект при смене диалога/эмоции
		_play_dialogue_change_effect(to_sprite, to_side, expression, false)
		
		# Запускаем idle эффекты с задержкой
		var delay_timer := Timer.new()
		delay_timer.wait_time = 0.3
		delay_timer.one_shot = true
		add_child(delay_timer)
		delay_timer.timeout.connect(func():
			_start_idle_effects(to_sprite, to_side, expression)
			delay_timer.queue_free()
		)
		delay_timer.start()
	)


## ============================================
## СИСТЕМА ЭФФЕКТОВ "ЖИВОСТИ" ПЕРСОНАЖЕЙ
## ============================================

func _start_idle_effects(sprite: Sprite2D, side: String, expression: String) -> void:
	"""Запустить эффекты живости для персонажа"""
	# Останавливаем предыдущие эффекты
	_stop_idle_effects(side)
	
	# Определяем интенсивность эффектов в зависимости от эмоции
	var intensity_multiplier := 1.0
	var shake_enabled := false
	
	match expression:
		"worried", "nervous", "scared", "cry":
			intensity_multiplier = 1.5
			shake_enabled = true
		"tired_at_factory", "tired_but_happy_factory":
			intensity_multiplier = 0.8
		"happy", "tired_but_happy_factory":
			intensity_multiplier = 1.2
		_:
			intensity_multiplier = 1.0
	
	# Сохраняем оригинальную позицию и масштаб
	var original_pos: Vector2
	var original_scale: Vector2
	
	if side == SIDE_LEFT:
		original_pos = _left_original_position
		original_scale = _left_original_scale
	else:
		original_pos = _right_original_position
		original_scale = _right_original_scale
	
	# Создаем отдельные tween'ы для каждого эффекта (параллельно)
	# Эффект 1: Дыхание (естественное движение вверх-вниз, как в VN)
	# СИЛЬНО УМЕНЬШЕНО для естественности
	var breathe_amount := 0.8 * intensity_multiplier  # Было 1.5, теперь 0.8
	var breathe_duration := 4.0 + randf() * 1.0  # 4.0-5.0 сек (медленнее)
	
	var breathe_tween := create_tween()
	breathe_tween.set_loops()  # Бесконечный цикл
	# Вдох (вверх) - очень легкий
	breathe_tween.tween_property(
		sprite, "position:y",
		original_pos.y - breathe_amount * 0.5,  # Вдох меньше
		breathe_duration * 0.45
	).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	# Выдох (вниз) - тоже легкий
	breathe_tween.tween_property(
		sprite, "position:y",
		original_pos.y + breathe_amount * 0.3,  # Выдох меньше
		breathe_duration * 0.55
	).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	
	# Эффект 2: Естественное покачивание (как в VN - ОЧЕНЬ легкое)
	# СИЛЬНО УМЕНЬШЕНО
	var sway_amount := 0.4 * intensity_multiplier  # Было 0.8, теперь 0.4
	var sway_duration := 6.0 + randf() * 2.0  # 6.0-8.0 сек (очень медленно)
	
	var sway_tween := create_tween()
	sway_tween.set_loops()  # Бесконечный цикл
	# Покачивание вправо
	sway_tween.tween_property(
		sprite, "position:x",
		original_pos.x + sway_amount,
		sway_duration
	).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	# Покачивание влево
	sway_tween.tween_property(
		sprite, "position:x",
		original_pos.x - sway_amount,
		sway_duration
	).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	
	# Эффект 3: Очень легкая пульсация (почти незаметная, как в VN)
	var pulse_amount := 0.005 * intensity_multiplier  # Было 0.01, теперь 0.005 (еще тоньше)
	var pulse_duration := 6.0 + randf() * 2.0  # 6.0-8.0 сек (очень медленно)
	
	var pulse_tween := create_tween()
	pulse_tween.set_loops()  # Бесконечный цикл
	# Легкое увеличение
	pulse_tween.tween_property(
		sprite, "scale",
		original_scale * (1.0 + pulse_amount),
		pulse_duration
	).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	# Возврат к нормальному размеру
	pulse_tween.tween_property(
		sprite, "scale",
		original_scale,
		pulse_duration
	).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	
	# Сохраняем все tween'ы
	if side == SIDE_LEFT:
		_left_idle_tweens = [breathe_tween, sway_tween, pulse_tween]
	else:
		_right_idle_tweens = [breathe_tween, sway_tween, pulse_tween]
	
	# Если нужен эффект дрожания (для нервных эмоций)
	if shake_enabled:
		_start_shake_effect(sprite, side, intensity_multiplier)


func _start_shake_effect(sprite: Sprite2D, side: String, intensity: float) -> void:
	"""Эффект дрожания для нервных эмоций (более плавный, как в VN)"""
	var original_pos: Vector2 = _left_original_position if side == SIDE_LEFT else _right_original_position
	
	# Используем Tween для более плавного дрожания
	var shake_tween := create_tween()
	shake_tween.set_loops()
	
	var shake_amount := 0.3 * intensity  # Уменьшено для более естественного вида
	var shake_duration := 0.1  # Быстрое дрожание
	
	# Создаем плавное дрожание через последовательные движения
	# Вправо
	shake_tween.tween_property(
		sprite, "position:x",
		original_pos.x + shake_amount,
		shake_duration
	).set_ease(Tween.EASE_IN_OUT)
	# Влево
	shake_tween.tween_property(
		sprite, "position:x",
		original_pos.x - shake_amount,
		shake_duration
	).set_ease(Tween.EASE_IN_OUT)
	# Вверх
	shake_tween.tween_property(
		sprite, "position:y",
		original_pos.y - shake_amount * 0.7,
		shake_duration
	).set_ease(Tween.EASE_IN_OUT)
	# Вниз
	shake_tween.tween_property(
		sprite, "position:y",
		original_pos.y + shake_amount * 0.7,
		shake_duration
	).set_ease(Tween.EASE_IN_OUT)
	# Возврат к центру
	shake_tween.tween_property(
		sprite, "position",
		original_pos,
		shake_duration
	).set_ease(Tween.EASE_IN_OUT)
	
	# Сохраняем tween
	if side == SIDE_LEFT:
		_left_idle_tweens.append(shake_tween)
	else:
		_right_idle_tweens.append(shake_tween)


func _play_dialogue_change_effect(sprite: Sprite2D, side: String, expression: String, is_new: bool) -> void:
	"""Эффект при смене диалога/эмоции (легкий shake или pop)"""
	var original_pos: Vector2 = _left_original_position if side == SIDE_LEFT else _right_original_position
	var original_scale: Vector2 = _left_original_scale if side == SIDE_LEFT else _right_original_scale
	
	# Сохраняем текущую позицию (на случай если уже есть idle эффекты)
	var current_pos = sprite.position
	var current_scale = sprite.scale
	
	# Определяем тип эффекта в зависимости от эмоции
	var effect_type := "gentle"  # По умолчанию мягкий эффект
	var effect_intensity := 1.0
	
	match expression:
		"worried", "nervous", "scared", "cry":
			effect_type = "shake"
			effect_intensity = 1.2
		"angry", "serious":
			effect_type = "pop"
			effect_intensity = 1.1
		"happy", "tired_but_happy_factory":
			effect_type = "bounce"
			effect_intensity = 1.0
		_:
			effect_type = "gentle"
			effect_intensity = 0.6
	
	var change_tween := create_tween()
	change_tween.set_parallel(false)  # Последовательно для правильной работы
	
	match effect_type:
		"shake":
			# Легкое дрожание при появлении
			var shake_amount := 2.0 * effect_intensity  # Уменьшено с 3.0
			var shake_duration := 0.15
			
			# Быстрое дрожание туда-обратно
			change_tween.tween_property(
				sprite, "position",
				current_pos + Vector2(shake_amount, 0),
				shake_duration * 0.3
			).set_ease(Tween.EASE_IN_OUT)
			change_tween.tween_property(
				sprite, "position",
				current_pos - Vector2(shake_amount, 0),
				shake_duration * 0.3
			).set_ease(Tween.EASE_IN_OUT)
			change_tween.tween_property(
				sprite, "position",
				original_pos,  # Возврат к оригинальной позиции
				shake_duration * 0.4
			).set_ease(Tween.EASE_IN_OUT)
		
		"pop":
			# Эффект "выпрыгивания" (как в VN)
			var pop_scale := 1.03 * effect_intensity  # Уменьшено с 1.05
			var pop_duration := 0.12
			
			change_tween.tween_property(
				sprite, "scale",
				current_scale * pop_scale,
				pop_duration
			).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
			change_tween.tween_property(
				sprite, "scale",
				original_scale,
				pop_duration
			).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
		
		"bounce":
			# Легкий подпрыг (для радостных эмоций)
			var bounce_amount := 3.0 * effect_intensity  # Уменьшено с 5.0
			var bounce_duration := 0.15
			
			change_tween.tween_property(
				sprite, "position:y",
				current_pos.y - bounce_amount,
				bounce_duration * 0.5
			).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
			change_tween.tween_property(
				sprite, "position:y",
				original_pos.y,
				bounce_duration * 0.5
			).set_ease(Tween.EASE_IN)
		
		"gentle":
			# Очень легкий эффект (по умолчанию)
			var gentle_scale := 1.015 * effect_intensity  # Уменьшено с 1.02
			var gentle_duration := 0.08
			
			change_tween.tween_property(
				sprite, "scale",
				current_scale * gentle_scale,
				gentle_duration
			).set_ease(Tween.EASE_OUT)
			change_tween.tween_property(
				sprite, "scale",
				original_scale,
				gentle_duration
			).set_ease(Tween.EASE_IN)


func _stop_idle_effects(side: String) -> void:
	"""Остановить эффекты живости для персонажа"""
	var sprite: Sprite2D
	var idle_tweens: Array[Tween]
	var original_pos: Vector2
	var original_scale: Vector2
	
	if side == SIDE_LEFT:
		sprite = _left_sprite
		idle_tweens = _left_idle_tweens
		original_pos = _left_original_position
		original_scale = _left_original_scale
		_left_idle_tweens = []
	else:
		sprite = _right_sprite
		idle_tweens = _right_idle_tweens
		original_pos = _right_original_position
		original_scale = _right_original_scale
		_right_idle_tweens = []
	
	# Останавливаем все tween'ы
	for tween in idle_tweens:
		if tween:
			tween.kill()
			
			# Удаляем таймер дрожания, если есть
			if tween.has_meta("shake_timer"):
				var shake_timer: Timer = tween.get_meta("shake_timer")
				if is_instance_valid(shake_timer):
					shake_timer.queue_free()
	
	# Возвращаем спрайт в исходное состояние
	if sprite:
		var reset_tween := create_tween()
		reset_tween.set_parallel(true)
		reset_tween.tween_property(sprite, "position", original_pos, 0.3)
		reset_tween.tween_property(sprite, "scale", original_scale, 0.3)

func hide_all() -> void:
	"""Скрыть всех персонажей"""
	_stop_idle_effects(SIDE_LEFT)
	_stop_idle_effects(SIDE_RIGHT)
	_left_sprite.hide()
	_right_sprite.hide()
	_left_character = null
	_right_character = null
