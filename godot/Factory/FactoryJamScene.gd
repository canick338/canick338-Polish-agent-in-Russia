extends Control
## Сцена мини-игры: Расфасовка повидла

@onready var timer_label: Label = $Container/InfoPanelContainer/InfoPanel/TimerLabel
@onready var score_label: Label = $Container/InfoPanelContainer/InfoPanel/ScoreLabel
@onready var progress_label: Label = $Container/InfoPanelContainer/InfoPanel/ProgressLabel
@onready var conveyor: Control = $Container/Conveyor
@onready var skip_button: Button = $Container/SkipButton
@onready var game_logic: FactoryJamGame = $FactoryJamGame
@onready var conveyor_background: TextureRect = $Container/Conveyor/Background

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
	
	# Настроить конвейер
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
		conveyor_background.modulate = Color(1, 1, 1)
	
	# НЕ запускаем игру автоматически - ждём сигнала от ScenePlayer
	# call_deferred("start_game_auto")
	
	update_ui()

func _create_audio_players():
	"""Создать аудио-плееры для звуков"""
	# Звук наклеивания наклейки
	sticker_sound = AudioStreamPlayer.new()
	sticker_sound.name = "StickerSound"
	add_child(sticker_sound)
	
	# Звук конвейера (зацикленный)
	conveyor_sound = AudioStreamPlayer.new()
	conveyor_sound.name = "ConveyorSound"
	conveyor_sound.autoplay = false
	add_child(conveyor_sound)

func _create_conveyor():
	"""Настроить визуальный конвейер"""
	if not conveyor_background:
		return
	
	# Используем уже существующий TextureRect из сцены
	conveyor_texture = conveyor_background
	
	# Настройка параметров текстуры
	conveyor_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	conveyor_texture.stretch_mode = TextureRect.STRETCH_TILE
	
	print("✅ Conveyor belt initialized.")

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
				
				# Wobble effect (покачивание при движении)
				var wobble_freq = 0.05
				var wobble_amp = 3.0
				# Используем position.x для синхронизации с движением
				jar.rotation_degrees = sin(jar.position.x * wobble_freq) * wobble_amp
				
				# Удалить банки, которые ушли за экран
				if jar.position.x > get_viewport_rect().size.x + 100:
					jars_to_remove.append(jar)
		
		# Удалить пропущенные банки
		for jar in jars_to_remove:
			# Проверяем, была ли банка помечена
			var is_labeled = false
			if jar.has_node("Sticker"):
				if jar.get_node("Sticker").visible:
					is_labeled = true
			
			remove_jar(jar)
			
			if not is_labeled and game_logic:
				game_logic.miss_jar()
		
		# Двигать конвейер постоянно (независимо от состояния игры)
		if conveyor_texture:
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
	
	# Установить z_index для банки, чтобы она была поверх ленты конвейера
	jar.z_index = 2  # Выше ленты (z_index = 1) и Background (z_index = 0)
	
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
	jar.z_index = 2  # Выше ленты конвейера (z_index = 1)
	
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
	if jar.has_method("add_sticker"):
		jar.add_sticker("OK")
	elif jar.has_method("label_jar"):
		jar.label_jar()
	else:
		# Создать наклейку визуально
		_add_sticker_to_jar(jar)
	
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

func remove_jar(jar: Control):
	"""Удалить банку"""
	if jar in jars:
		jars.erase(jar)
	if is_instance_valid(jar):
		jar.queue_free()

func _on_jar_labeled(combo: int, current_score: int):
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
			
			# Частицы
			_create_label_particles(last_jar.position + Vector2(last_jar.size.x/2, last_jar.size.y/2))
			
			# Текст комбо (если комбо > 1)
			if combo > 1:
				_show_floating_text(last_jar.position, "Combo x%d!" % combo, Color(1, 0.8, 0.2))
			else:
				_show_floating_text(last_jar.position, "+10", Color(0.2, 1, 0.2))

func _on_jar_missed():
	"""Банка пропущена"""
	# Эффект провала - затемнение экрана или красная вспышка
	var flash = ColorRect.new()
	flash.color = Color(1, 0, 0, 0.3)
	flash.anchors_preset = Control.PRESET_FULL_RECT
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)
	
	var tween = create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.3)
	tween.tween_callback(flash.queue_free)
	
	_show_floating_text(Vector2(get_viewport_rect().size.x - 100, get_viewport_rect().size.y/2), "Miss!", Color(1, 0.2, 0.2))

func _create_label_particles(pos: Vector2):
	"""Создать эффект частиц"""
	var particles = CPUParticles2D.new()
	particles.position = pos
	particles.amount = 10
	particles.lifetime = 0.5
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.spread = 180.0
	particles.gravity = Vector2(0, 500)
	particles.initial_velocity_min = 100.0
	particles.initial_velocity_max = 200.0
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 4.0
	particles.color = Color(1, 1, 0.5)
	
	# Контейнер для частиц (важно чтобы они были поверх банок)
	if conveyor:
		conveyor.add_child(particles)
	else:
		add_child(particles)
		
	# Удаление после завершения
	await get_tree().create_timer(1.0).timeout
	particles.queue_free()

func _show_floating_text(pos: Vector2, text: String, color: Color):
	"""Показать всплывающий текст"""
	var label = Label.new()
	label.text = text
	label.modulate = color
	label.position = pos + Vector2(0, -20)
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	
	if conveyor:
		conveyor.add_child(label)
	else:
		add_child(label)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", pos.y - 80, 0.8).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.8).set_ease(Tween.EASE_IN)
	tween.tween_callback(label.queue_free).set_delay(0.8)

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
	if not game_logic:
		return
		
	var progress = float(game_logic.jars_labeled) / float(game_logic.required_jars) * 100.0
	
	if score_label:
		score_label.text = "📊 Очки: %d (Комбо: x%d)" % [game_logic.score, game_logic.combo_count]
	
	if progress_label:
		progress_label.text = "✅ Помечено: %d/%d (%.0f%%)" % [game_logic.jars_labeled, game_logic.required_jars, progress]
		
		# Зелёный цвет при хорошем прогрессе
		if progress >= 100:
			progress_label.modulate = Color(0.3, 1, 0.3)  # Зелёный
		elif progress >= 70:
			progress_label.modulate = Color(1, 1, 0.3)  # Жёлтый
		else:
			progress_label.modulate = Color(1, 1, 1)  # Белый
