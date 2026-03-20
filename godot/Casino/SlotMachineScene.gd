extends Control
## Слот-машина "Три топора" - игра типа 777

@onready var reel_1: TextureRect = $Container/ReelsContainer/Reel1
@onready var reel_2: TextureRect = $Container/ReelsContainer/Reel2
@onready var reel_3: TextureRect = $Container/ReelsContainer/Reel3
@onready var spin_button: Button = $Container/Controls/SpinButton
@onready var skip_button: Button = $Container/Controls/SkipButton
@onready var message_label: Label = $Container/MessageLabel
@onready var game_logic: SlotMachineGame = $SlotMachineGame

var reels: Array[TextureRect] = []
var is_spinning: bool = false
var reel_spinning: Array[bool] = [false, false, false]
var spin_time: Array[float] = [0.0, 0.0, 0.0]

# Текстуры для топоров
var normal_axe_texture: ImageTexture
var golden_axe_texture: ImageTexture

signal casino_finished(is_win: bool)

func _ready():
	# Инициализировать массивы
	reels = [reel_1, reel_2, reel_3]
	reel_spinning = [false, false, false]
	spin_time = [0.0, 0.0, 0.0]
	
	# Создать текстуры топоров
	normal_axe_texture = AxeTextureGenerator.create_axe_texture(Vector2(200, 300), false)
	golden_axe_texture = AxeTextureGenerator.create_axe_texture(Vector2(200, 300), true)
	
	# Установить начальные текстуры
	for reel in reels:
		reel.texture = normal_axe_texture
	
	# Подключить сигналы
	game_logic.spin_started.connect(_on_spin_started)
	game_logic.game_finished.connect(_on_game_finished)
	game_logic.reel_stopped.connect(_on_reel_stopped)
	
	spin_button.pressed.connect(_on_spin_button_pressed)
	skip_button.pressed.connect(_on_skip_button_pressed)
	
	update_message("Три топора... Сыграем?")

func _process(delta):
	"""Обновление анимации вращения"""
	if not is_spinning:
		return
	
	# Быстрое переключение текстур для эффекта вращения
	for i in range(3):
		if reel_spinning[i]:
			spin_time[i] += delta
			# Переключать каждые 0.1 секунды
			if spin_time[i] >= 0.1:
				spin_time[i] = 0.0
				# Быстро переключать между текстурами
				if reels[i].texture == normal_axe_texture:
					reels[i].texture = golden_axe_texture
				else:
					reels[i].texture = normal_axe_texture

func _on_spin_button_pressed():
	"""Начать вращение"""
	if is_spinning:
		return
	
	game_logic.start_spin()

func _on_skip_button_pressed():
	"""Пропустить казино и перейти к сюжету"""
	# Остановить игру если она идет
	if is_spinning:
		is_spinning = false
		for i in range(3):
			reel_spinning[i] = false
	
	# Сразу перейти к сюжету
	update_message("Пропущено...")
	casino_finished.emit(false)

func _on_spin_started():
	"""Началось вращение - запустить анимацию"""
	is_spinning = true
	spin_button.disabled = true
	AudioManager.play_event("minigame_start")
	update_message("Крутится...")
	
	# Запустить вращение для всех барабанов
	for i in range(3):
		reel_spinning[i] = true
		spin_time[i] = 0.0

func _on_reel_stopped(reel_index: int, result: int):
	"""Остановить конкретный барабан"""
	if reel_index >= reels.size():
		return
	
	var reel = reels[reel_index]
	
	# Остановить вращение этого барабана
	reel_spinning[reel_index] = false
	
	# Установить финальную текстуру
	if result == 1:  # Золотой топор
		reel.texture = golden_axe_texture
	else:  # Обычный топор
		reel.texture = normal_axe_texture
	
	# Анимация остановки (прыжок)
	var original_pos = reel.position
	var stop_tween = create_tween()
	stop_tween.tween_property(reel, "position:y", original_pos.y - 15, 0.1)
	stop_tween.tween_property(reel, "position:y", original_pos.y, 0.1)
	AudioManager.play_event("card_deal")

func _on_game_finished(is_win: bool):
	"""Игра закончена"""
	is_spinning = false
	
	# Остановить все вращения
	for i in range(3):
		reel_spinning[i] = false
	
	# Показать результат
	if is_win:
		AudioManager.play_event("match_victory")
		update_message("ДЖЕКПОТ! ТРИ ТОПОРА! 🎉🎉🎉")
		animate_win()
	else:
		AudioManager.play_event("round_lose")
		update_message("Не повезло! Попробуйте еще раз!")
	
	# Переход к сюжету через небольшую задержку (вне зависимости от результата)
	await get_tree().create_timer(3.0).timeout
	casino_finished.emit(is_win)

func animate_win():
	"""Анимация выигрыша"""
	var win_tween = create_tween()
	win_tween.set_parallel(true)
	
	# Пульсация всех топоров
	for reel in reels:
		win_tween.tween_property(reel, "modulate", Color.GOLD, 0.3)
		win_tween.tween_property(reel, "modulate", Color.WHITE, 0.3).set_delay(0.3)
	
	win_tween.set_loops(3)

func update_message(text: String):
	"""Обновить сообщение"""
	message_label.text = text

