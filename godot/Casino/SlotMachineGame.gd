extends Node
class_name SlotMachineGame
## Слот-машина "Три топора" - игра типа 777

signal game_finished(is_win: bool)
signal spin_started()
signal reel_stopped(reel_index: int, result: int)

enum GameState {
	WAITING,      # Ожидание начала игры
	SPINNING,     # Барабаны крутятся
	STOPPING,     # Барабаны останавливаются
	FINISHED      # Игра закончена
}

var current_state: GameState = GameState.WAITING
var reel_results: Array[int] = [0, 0, 0]  # Результаты каждого барабана (0=обычный, 1=золотой)
var is_winning: bool = false  # Выигрыш (три одинаковых)

# Настройки игры
@export var spin_duration: float = 2.0  # Время вращения в секундах
@export var reel_stop_delay: float = 0.3  # Задержка между остановками барабанов

func start_spin():
	"""Начать вращение барабанов"""
	if current_state != GameState.WAITING:
		return
	
	current_state = GameState.SPINNING
	spin_started.emit()
	
	# Генерируем случайные результаты
	reel_results[0] = randi() % 2  # 0 или 1
	reel_results[1] = randi() % 2
	reel_results[2] = randi() % 2
	
	# Проверяем выигрыш (три одинаковых)
	is_winning = (reel_results[0] == reel_results[1] and reel_results[1] == reel_results[2])
	
	# Небольшая задержка перед остановкой
	await get_tree().create_timer(spin_duration).timeout
	stop_reels()

func stop_reels():
	"""Остановить барабаны по очереди"""
	current_state = GameState.STOPPING
	
	# Останавливаем барабаны с задержкой
	for i in range(3):
		reel_stopped.emit(i, reel_results[i])
		if i < 2:
			await get_tree().create_timer(reel_stop_delay).timeout
	
	# Финальная проверка результата
	current_state = GameState.FINISHED
	game_finished.emit(is_winning)

func reset_game():
	"""Сбросить игру"""
	current_state = GameState.WAITING
	reel_results = [0, 0, 0]
	is_winning = false











