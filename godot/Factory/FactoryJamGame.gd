extends Node
class_name FactoryJamGame
## Мини-игра: Расфасовка повидла на конвейере

signal game_finished(score: int, jars_labeled: int, jars_missed: int)

enum GameState {
	WAITING,      # Ожидание начала
	PLAYING,     # Игра идёт
	FINISHED     # Игра закончена
}

var current_state: GameState = GameState.WAITING
var score: int = 0
var jars_labeled: int = 0
var jars_missed: int = 0
var total_jars: int = 0

# Настройки игры
@export var game_duration: float = 30.0  # Длительность игры в секундах
@export var jar_spawn_interval: float = 1.2  # Интервал появления банок (быстрее)
@export var jar_speed: float = 250.0  # Скорость движения банок (быстрее)
@export var required_jars: int = 15  # Минимум банок для прохождения
@export var difficulty_multiplier: float = 1.0  # Множитель сложности

var time_remaining: float = 0.0
var jar_spawn_timer: float = 0.0

func start_game():
	"""Начать игру"""
	if current_state != GameState.WAITING:
		return
	
	current_state = GameState.PLAYING
	score = 0
	jars_labeled = 0
	jars_missed = 0
	total_jars = 0
	time_remaining = game_duration
	jar_spawn_timer = 0.0

func _process(delta: float):
	"""Обновление игры"""
	if current_state != GameState.PLAYING:
		return
	
	time_remaining -= delta
	jar_spawn_timer -= delta
	
	# Увеличивать сложность со временем (ускорение спавна)
	var time_passed = game_duration - time_remaining
	if time_passed > 10.0:
		# После 10 секунд ускоряем спавн
		var speed_multiplier = 1.0 + (time_passed - 10.0) / 20.0
		jar_spawn_timer -= delta * (speed_multiplier - 1.0)
	
	# Проверка окончания времени
	if time_remaining <= 0.0:
		finish_game()
		return
	
	# Спавн новых банок
	if jar_spawn_timer <= 0.0:
		# Случайный интервал для разнообразия
		jar_spawn_timer = jar_spawn_interval * randf_range(0.8, 1.2)
		spawn_jar_requested.emit()

var combo_count: int = 0
var max_combo: int = 0

signal spawn_jar_requested()

func label_jar():
	"""Игрок наклеил наклейку на банку"""
	if current_state != GameState.PLAYING:
		return
	
	jars_labeled += 1
	total_jars += 1
	
	# Combo logic
	combo_count += 1
	if combo_count > max_combo:
		max_combo = combo_count
	
	# Score multiplier based on combo (max x3)
	var multiplier = min(1 + (combo_count / 5), 3)
	score += 10 * multiplier
	
	jar_labeled.emit(combo_count, score)

signal jar_labeled(combo_count, current_score)

func miss_jar():
	"""Банка ушла без наклейки"""
	if current_state != GameState.PLAYING:
		return
	
	jars_missed += 1
	total_jars += 1
	
	# Reset combo
	combo_count = 0
	
	score -= 5
	jar_missed.emit()

signal jar_missed()

func finish_game():
	"""Завершить игру"""
	# Если игра еще не началась или уже закончена, все равно отправляем результаты
	# Это важно для случая, когда игрок пропускает игру
	if current_state == GameState.WAITING:
		# Игра была пропущена до начала - устанавливаем минимальные значения
		score = 0
		jars_labeled = 0
		jars_missed = 0
		total_jars = 0
	
	current_state = GameState.FINISHED
	game_finished.emit(score, jars_labeled, jars_missed)

func get_time_remaining() -> float:
	"""Получить оставшееся время"""
	return max(0.0, time_remaining)

func is_passed() -> bool:
	"""Проверить, прошёл ли игрок минимум"""
	return jars_labeled >= required_jars
