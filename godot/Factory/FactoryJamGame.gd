extends Node
class_name FactoryJamGame
## Мини-игра: "Волк ловит яйца" (но с банками)

signal game_finished(score: int, jars_labeled: int, jars_missed: int)
signal score_updated(new_score: int)
signal lives_updated(lives: int)
signal spawn_jar_requested(lane: int, speed: float, is_rotten: bool)

enum GameState {
	WAITING,
	PLAYING,
	FINISHED
}

# Позиции для спавна (0=LT, 1=LB, 2=RT, 3=RB)
enum Lane {
	LEFT_TOP = 0,
	LEFT_BOTTOM = 1,
	RIGHT_TOP = 2,
	RIGHT_BOTTOM = 3
}

var current_state: GameState = GameState.WAITING
var score: int = 0
var lives: int = 3
var jars_caught: int = 0  # Аналог "jars_labeled"
var jars_broken: int = 0  # Аналог "jars_missed"

# Настройки сложности
@export var max_lives: int = 3
@export var base_speed: float = 150.0
@export var spawn_interval: float = 2.0
@export var acceleration: float = 0.05 # На сколько уменьшать интервал спавна

var spawn_timer: float = 0.0
var speed_multiplier: float = 1.0

func start_game():
	"""Начать игру"""
	current_state = GameState.PLAYING
	score = 0
	lives = max_lives
	jars_caught = 0
	jars_broken = 0
	speed_multiplier = 1.0
	spawn_timer = spawn_interval
	
	emit_signal("score_updated", score)
	emit_signal("lives_updated", lives)

func _process(delta: float):
	if current_state != GameState.PLAYING:
		return
	
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_jar()
		# Сброс таймера с учетом ускорения
		var current_interval = max(0.5, spawn_interval / speed_multiplier)
		spawn_timer = current_interval
		
		# Ускоряем игру со временем
		speed_multiplier += 0.02

func spawn_jar():
	"""Спавн банки в случайной линии"""
	var lane = randi() % 4
	var speed = base_speed * speed_multiplier
	var is_rotten = (randf() < 0.25) # 25% chance
	spawn_jar_requested.emit(lane, speed, is_rotten)

func catch_jar():
	"""Игрок поймал банку"""
	if current_state != GameState.PLAYING:
		return
		
	score += 1
	jars_caught += 1
	score_updated.emit(score)
	
	# Каждые 10/100 очков можно, например, восстанавливать жизнь (классика)
	if score > 0 and score % 200 == 0:
		if lives < max_lives:
			lives += 1
			lives_updated.emit(lives)
			
	# Победа при достижении 20 очков
	if score >= 20:
		finish_game()

func hit_rotten_jar():
	"""Игрок поймал ГНИЛУЮ банку (минус жизнь)"""
	if current_state != GameState.PLAYING:
		return
		
	lives -= 1
	lives_updated.emit(lives)
	
	if lives <= 0:
		finish_game()
	
	# if lives <= 0: <-- Removed
	# 	finish_game()

func miss_jar():
	"""Игрок пропустил банку (разбилась)"""
	if current_state != GameState.PLAYING:
		return
		
	lives -= 1
	jars_broken += 1
	lives_updated.emit(lives)
	
	if lives <= 0:
		finish_game()

func finish_game():
	"""Конец игры"""
	current_state = GameState.FINISHED
	game_finished.emit(score, jars_caught, jars_broken)

func is_passed() -> bool:
	# Условие прохождения
	return score >= 20
