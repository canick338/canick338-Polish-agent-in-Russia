extends Control
## Сцена мини-игры: Расфасовка повидла

@onready var timer_label: Label = $Container/InfoPanel/TimerLabel
@onready var score_label: Label = $Container/InfoPanel/ScoreLabel
@onready var conveyor: Control = $Container/Conveyor
@onready var skip_button: Button = $Container/SkipButton
@onready var game_logic: FactoryJamGame = $FactoryJamGame
@onready var conveyor_background: ColorRect = $Container/Conveyor/Background

var jar_scene: PackedScene
var jars: Array[Control] = []
var jar_speed: float = 200.0

# Звуки
var sticker_sound: AudioStreamPlayer
var conveyor_sound: AudioStreamPlayer

# Конвейер
var conveyor_texture: TextureRect
var conveyor_offset: float = 0.0
var conveyor_speed: float = 100.0

signal factory_game_finished(score: int, jars_labeled: int, jars_missed: int)

func _ready():
	# Загрузить сцену банки
	jar_scene = load("res://Factory/Jar.tscn") as PackedScene
	
	# Создать звуки
	_create_audio_players()
	
	# Создать движущийся конвейер
	_create_conveyor()
	
	# Подключить сигналы
	if game_logic:
		game_logic.game_finished.connect(_on_game_finished)
		game_logic.spawn_jar_requested.connect(_on_spawn_jar)
		game_logic.jar_labeled.connect(_on_jar_labeled)
		game_logic.jar_missed.connect(_on_jar_missed)
	
	# Подключить кнопку пропуска
	if skip_button:
		skip_button.pressed.connect(_on_skip_button_pressed)
	
	# Скрыть кнопку пропуска в начале
	if skip_button:
		skip_button.hide()
	
	# Настроить конвейер
	if conveyor_background:
		conveyor_background.color = Color(0.3, 0.3, 0.3)  # Серый конвейер
	
	# НЕ запускаем игру автоматически - ждём сигнала от ScenePlayer
	# call_deferred("start_game_auto")
	
	update_ui()

func _create_audio_players():
	"""Создать аудио-плееры для звуков"""
	# Звук наклеивания наклейки
	sticker_sound = AudioStreamPlayer.new()
	sticker_sound.name = "StickerSound"
	add_child(sticker_sound)
	# Загрузить звук если есть (опционально)
	# sticker_sound.stream = load("res://Factory/Sounds/sticker_sound.ogg")
	
	# Звук конвейера (зацикленный)
	conveyor_sound = AudioStreamPlayer.new()
	conveyor_sound.name = "ConveyorSound"
	conveyor_sound.autoplay = false
	add_child(conveyor_sound)
	# Загрузить звук если есть (опционально)
	# conveyor_sound.stream = load("res://Factory/Sounds/conveyor_sound.ogg")

func _create_conveyor():
	"""Создать визуальный конвейер с текстурой"""
	if not conveyor:
		return
	
	# Создать TextureRect для конвейерной ленты
	conveyor_texture = TextureRect.new()
	conveyor_texture.name = "ConveyorTexture"
	conveyor_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	conveyor_texture.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	conveyor_texture.stretch_mode = TextureRect.STRETCH_TILE
	conveyor_texture.anchors_preset = Control.PRESET_FULL_RECT
	conveyor_texture.grow_horizontal = Control.GROW_DIRECTION_BOTH
	conveyor_texture.grow_vertical = Control.GROW_DIRECTION_BOTH
	
	# Если есть текстура конвейера, загрузить её
	# var conveyor_img = load("res://Factory/Textures/conveyor_belt.png")
	# if conveyor_img:
	# 	conveyor_texture.texture = conveyor_img
	# else:
	# 	# Временная текстура - полосы
	# 	conveyor_texture.modulate = Color(0.4, 0.4, 0.4)
	
	# Добавить в конвейер (под банками)
	conveyor.add_child(conveyor_texture)
	conveyor.move_child(conveyor_texture, 0)  # Переместить в начало (под Background)

func _input(event: InputEvent):
	"""Обработка кликов по банкам через глобальный input"""
	if not game_logic or game_logic.current_state != FactoryJamGame.GameState.PLAYING:
		return
	
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			# Найти банку под курсором
			var mouse_pos = get_global_mouse_position()
			for jar in jars:
				if jar and is_instance_valid(jar):
					var jar_global_pos = jar.get_global_position()
					# Учитываем, что jar может быть дочерним элементом conveyor
					if conveyor:
						jar_global_pos = conveyor.get_global_position() + jar.position
					var jar_rect = Rect2(jar_global_pos, jar.size)
					if jar_rect.has_point(mouse_pos):
						_on_jar_clicked(jar)
						break

func _process(delta: float):
	"""Обновление игры"""
	if not game_logic:
		return
		
	if game_logic.current_state == FactoryJamGame.GameState.PLAYING:
		# Обновить таймер с цветовой индикацией
		var time = game_logic.get_time_remaining()
		if timer_label:
			timer_label.text = "⏱ Время: %.1f сек" % time
			# Красный цвет при малом времени
			if time < 5.0:
				timer_label.modulate = Color(1, 0.3, 0.3)  # Красный
			elif time < 10.0:
				timer_label.modulate = Color(1, 0.7, 0.3)  # Оранжевый
			else:
				timer_label.modulate = Color(1, 1, 1)  # Белый
		
		# Двигать банки
		var jars_to_remove = []
		for jar in jars:
			if jar and is_instance_valid(jar):
				jar.position.x += jar_speed * delta
				
				# Удалить банки, которые ушли за экран
				if jar.position.x > get_viewport_rect().size.x + 100:
					jars_to_remove.append(jar)
		
		# Удалить пропущенные банки
		for jar in jars_to_remove:
			remove_jar(jar)
			if game_logic:
				game_logic.miss_jar()
		
		# Двигать конвейер
		if conveyor_texture and game_logic.current_state == FactoryJamGame.GameState.PLAYING:
			conveyor_offset += conveyor_speed * delta
			# Зациклить смещение для бесшовного движения
			if conveyor_texture.texture:
				var texture_width = conveyor_texture.texture.get_width()
				if texture_width > 0:
					conveyor_offset = fmod(conveyor_offset, texture_width)
					conveyor_texture.offset_left = -conveyor_offset
					conveyor_texture.offset_right = conveyor_offset
			else:
				# Если нет текстуры, используем modulate для эффекта
				conveyor_offset = fmod(conveyor_offset, 100.0)
		
		update_ui()

func start_game_auto():
	"""Автоматически начать игру"""
	if game_logic:
		game_logic.start_game()
	if skip_button:
		skip_button.show()
	
	# Запустить звук конвейера
	if conveyor_sound and conveyor_sound.stream:
		conveyor_sound.play()

func start_game_manual():
	"""Начать игру вручную (вызывается из ScenePlayer после диалога)"""
	start_game_auto()

func _on_skip_button_pressed():
	"""Пропустить мини-игру"""
	# Завершить с минимальным результатом
	if game_logic:
		game_logic.finish_game()

func _on_spawn_jar():
	"""Создать новую банку"""
	var jar: Control = null
	
	if jar_scene and jar_scene.can_instantiate():
		jar = jar_scene.instantiate()
	
	if not jar:
		# Если сцена не загружена, создаём простую банку
		jar = create_simple_jar()
	
	if not jar:
		return
	
	# Случайная позиция по Y для разнообразия
	var y_offset = randf_range(-50, 50)
	jar.position = Vector2(-100, conveyor.size.y / 2 - 25 + y_offset)
	
	# Добавить небольшую случайную задержку для разнообразия
	var spawn_delay = randf_range(0.0, 0.3)
	if spawn_delay > 0:
		await get_tree().create_timer(spawn_delay).timeout
	
	conveyor.add_child(jar)
	jars.append(jar)
	
	# Анимация появления
	var tween = create_tween()
	jar.modulate = Color(1, 1, 1, 0)
	tween.tween_property(jar, "modulate", Color(1, 1, 1, 1), 0.2)
	
	# Подключить клик - используем универсальный метод
	if jar.has_signal("jar_clicked"):
		jar.jar_clicked.connect(_on_jar_clicked.bind(jar))
	
	# Всегда добавляем обработчик gui_input для надёжности
	jar.gui_input.connect(_on_jar_gui_input.bind(jar))

func _add_sticker_to_jar(jar: Control):
	"""Добавить визуальную наклейку на банку"""
	if not jar or not is_instance_valid(jar):
		return
	
	# Проверить, нет ли уже наклейки
	for child in jar.get_children():
		if child.name == "Sticker":
			child.visible = true
			child.modulate = Color(1, 1, 1, 1)
			return
	
	# Создать наклейку
	var sticker = ColorRect.new()
	sticker.name = "Sticker"
	sticker.color = Color(1, 0.2, 0.2, 0.8)  # Красная наклейка
	sticker.size = Vector2(jar.size.x * 0.8, jar.size.y * 0.25)
	sticker.position = Vector2(jar.size.x * 0.1, jar.size.y * 0.05)
	sticker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	jar.add_child(sticker)
	
	# Анимация появления
	var tween = create_tween()
	sticker.modulate = Color(1, 1, 1, 0)
	tween.tween_property(sticker, "modulate", Color(1, 1, 1, 1), 0.2)

func _create_click_effect(jar: Control):
	"""Создать визуальный эффект при клике"""
	if not jar or not is_instance_valid(jar):
		return
	
	# Простой эффект - вспышка
	var flash = ColorRect.new()
	flash.color = Color(1, 1, 0.3, 0.5)  # Жёлтая вспышка
	flash.size = jar.size
	flash.position = Vector2.ZERO
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	jar.add_child(flash)
	
	# Анимация исчезновения
	var tween = create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.3)
	tween.tween_callback(flash.queue_free)

func create_simple_jar() -> Control:
	"""Создать простую банку если сцена не загружена"""
	var jar = Control.new()
	jar.custom_minimum_size = Vector2(80, 120)
	jar.mouse_filter = Control.MOUSE_FILTER_STOP
	jar.name = "SimpleJar"
	
	# Тело банки (цилиндр)
	var body = ColorRect.new()
	body.color = Color(0.9, 0.85, 0.75)  # Светло-бежевый
	body.size = Vector2(60, 100)
	body.position = Vector2(10, 10)
	jar.add_child(body)
	
	# Крышка
	var lid = ColorRect.new()
	lid.color = Color(0.7, 0.5, 0.3)  # Коричневая крышка
	lid.size = Vector2(60, 15)
	lid.position = Vector2(10, 5)
	jar.add_child(lid)
	
	# Повидло внутри
	var jam = ColorRect.new()
	jam.color = Color(0.8, 0.4, 0.1)  # Оранжевое повидло
	jam.size = Vector2(50, 60)
	jam.position = Vector2(15, 50)
	jar.add_child(jam)
	
	# Эмодзи для красоты
	var label = Label.new()
	label.text = "🍯"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size = Vector2(80, 120)
	label.add_theme_font_size_override("font_size", 40)
	jar.add_child(label)
	
	return jar

func _on_jar_gui_input(event: InputEvent, jar: Control):
	"""Обработчик клика для банок"""
	if not jar or not is_instance_valid(jar):
		return
		
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			# Проверить, что клик внутри банки
			var local_pos = jar.get_local_mouse_position()
			var jar_rect = Rect2(Vector2.ZERO, jar.size)
			if jar_rect.has_point(local_pos):
				_on_jar_clicked(jar)
				# Остановить распространение события
				get_viewport().set_input_as_handled()

func _on_jar_clicked(jar: Control = null):
	"""Игрок кликнул на банку"""
	if not jar or not is_instance_valid(jar):
		return
		
	if not game_logic or game_logic.current_state != FactoryJamGame.GameState.PLAYING:
		return
	
	# Проверить, не помечена ли уже банка
	if jar.has_method("is_labeled") and jar.is_labeled():
		return
	
	# Пометить банку в логике игры
	game_logic.label_jar()
	
	# Воспроизвести звук наклеивания
	_play_sticker_sound()
	
	# Добавить визуальную наклейку с анимацией
	if jar.has_method("label_jar"):
		jar.label_jar()
	else:
		# Создать наклейку визуально
		_add_sticker_to_jar(jar)
	
	# Анимация наклеивания наклейки
	_animate_sticker_application(jar)
	
	# Анимация успеха банки
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(jar, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(jar, "scale", Vector2(1.0, 1.0), 0.1).set_delay(0.1)
	
	# Эффект частиц (визуальный)
	_create_click_effect(jar)

func _play_sticker_sound():
	"""Воспроизвести звук наклеивания наклейки"""
	if sticker_sound:
		if sticker_sound.stream:
			sticker_sound.play()
		else:
			# Генерируем простой звук программно (опционально)
			pass

func _animate_sticker_application(jar: Control):
	"""Анимация наклеивания наклейки"""
	if not jar or not is_instance_valid(jar):
		return
	
	# Найти наклейку
	var sticker = null
	for child in jar.get_children():
		if child.name == "Sticker":
			sticker = child
			break
	
	if not sticker:
		return
	
	# Анимация: наклейка появляется сверху и "приклеивается"
	sticker.visible = true
	sticker.modulate = Color(1, 1, 1, 0)
	sticker.scale = Vector2(0.5, 0.5)
	sticker.position.y = -20  # Начать сверху
	
	var tween = create_tween()
	tween.set_parallel(true)
	# Движение вниз
	tween.tween_property(sticker, "position:y", 0, 0.2).set_ease(Tween.EASE_OUT)
	# Появление
	tween.tween_property(sticker, "modulate:a", 1.0, 0.15)
	# Увеличение
	tween.tween_property(sticker, "scale", Vector2(1.1, 1.1), 0.15)
	# Небольшой "отскок" при приклеивании
	tween.tween_property(sticker, "scale", Vector2(1.0, 1.0), 0.1).set_delay(0.15).set_ease(Tween.EASE_IN)

func remove_jar(jar: Control):
	"""Удалить банку"""
	if jar in jars:
		jars.erase(jar)
	if is_instance_valid(jar):
		jar.queue_free()

func _on_jar_labeled():
	"""Банка помечена"""
	# Эффект успеха - найти последнюю банку и добавить эффект
	if jars.size() > 0:
		var last_jar = jars[jars.size() - 1]
		if last_jar and is_instance_valid(last_jar):
			# Анимация успеха
			var tween = create_tween()
			tween.set_parallel(true)
			tween.tween_property(last_jar, "scale", Vector2(1.2, 1.2), 0.1)
			tween.tween_property(last_jar, "scale", Vector2(1.0, 1.0), 0.1).set_delay(0.1)

func _on_jar_missed():
	"""Банка пропущена"""
	# Эффект провала - затемнение
	pass

func _on_game_finished(score: int, jars_labeled: int, jars_missed: int):
	"""Игра закончена"""
	update_ui()
	
	# Показать результат
	var result_text = "Игра окончена!\n"
	result_text += "Банок помечено: %d\n" % jars_labeled
	result_text += "Банок пропущено: %d\n" % jars_missed
	result_text += "Очки: %d\n" % score
	
	if game_logic and game_logic.is_passed():
		result_text += "\n✅ Задание выполнено!"
	elif game_logic:
		result_text += "\n❌ Нужно минимум %d банок!" % game_logic.required_jars
	
	if timer_label:
		timer_label.text = result_text
	
	# Переход к сюжету через задержку
	await get_tree().create_timer(3.0).timeout
	factory_game_finished.emit(score, jars_labeled, jars_missed)

func update_ui():
	"""Обновить интерфейс"""
	if score_label and game_logic:
		var progress = float(game_logic.jars_labeled) / float(game_logic.required_jars) * 100.0
		score_label.text = "📊 Очки: %d | ✅ Помечено: %d/%d (%.0f%%)" % [game_logic.score, game_logic.jars_labeled, game_logic.required_jars, progress]
		
		# Зелёный цвет при хорошем прогрессе
		if progress >= 100:
			score_label.modulate = Color(0.3, 1, 0.3)  # Зелёный
		elif progress >= 70:
			score_label.modulate = Color(1, 1, 0.3)  # Жёлтый
		else:
			score_label.modulate = Color(1, 1, 1)  # Белый
