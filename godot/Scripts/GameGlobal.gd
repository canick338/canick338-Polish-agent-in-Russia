extends Node

# Глобальный синглтон для хранения данных
# Доступен везде как 'GameGlobal'

# === БАЗА ДАННЫХ КАРТОЧЕК ===
# Здесь мы добавляем новые карточки.
# Формат: "id": { properties }
const CARD_DATABASE = {
	"card_danila_happy": {
		"name": "Счастливый Данила",
		"description": "Редкий момент улыбки на заводе.",
		"texture_path": "res://Characters/Danila/danila_happy.png",
		"unlock_type": "event", # event = за действия, buy = за деньги
		"cost": 0
	},
	"card_worker_smug": {
		"name": "Хитрый Рабочий",
		"description": "Он знает, как обмануть систему.",
		"texture_path": "res://Characters/Worker/worker_smug_1767808888945.png",
		"unlock_type": "buy",
		"cost": 50
	},
	"card_boss_angry": {
		"name": "Ярость Босса",
		"description": "Лучше не попадаться ему на глаза.",
		"texture_path": "res://Characters/boss_of_factory/boss_of_factory.png",
		"unlock_type": "event",
		"cost": 0
	},
	"card_danila_sad": {
		"name": "Грустный Данила",
		"description": "Когда снова задержали зарплату.",
		"texture_path": "res://Characters/Danila/danila_sad.png",
		"unlock_type": "buy",
		"cost": 100
	}
}

# === СОСТОЯНИЕ ИГРЫ ===
# Переменные, которые мы сохраняем
var save_data = {
	"money": 30,
	"unlocked_cards": [] # Список ID открытых карточек
}

# Путь к файлу сохранения
const SAVE_PATH = "user://savegame.dat"

# Авто-загрузка при старте
func _ready():
	load_game()

# === УПРАВЛЕНИЕ ДЕНЬГАМИ ===
# (Обертки для удобства, работают с save_data)
# Static функции убраны, чтобы работать с экземпляром (Autoload сам является экземпляром)
# Но для совместимости оставим static-like доступ через GameGlobal.property, если бы это был класс.
# В Godot Autoload - это Node. Обращаемся к нему по имени.

var player_money: int:
	get: return save_data["money"]
	set(value): 
		save_data["money"] = value
		save_game()

func add_money(amount: int):
	player_money += amount
	print("Money added: ", amount, ". Total: ", player_money)

func remove_money(amount: int) -> bool:
	if player_money >= amount:
		player_money -= amount
		print("Money removed: ", amount, ". Total: ", player_money)
		return true
	return false

# === УПРАВЛЕНИЕ КОЛЛЕКЦИЕЙ ===

func is_card_unlocked(card_id: String) -> bool:
	return card_id in save_data["unlocked_cards"]

func unlock_card(card_id: String):
	if not is_card_unlocked(card_id):
		save_data["unlocked_cards"].append(card_id)
		print("Card unlocked: ", card_id)
		save_game()

func buy_card(card_id: String) -> bool:
	if card_id not in CARD_DATABASE:
		return false
	
	var card = CARD_DATABASE[card_id]
	if is_card_unlocked(card_id):
		return true # Уже открыта
		
	if card["unlock_type"] == "buy":
		if remove_money(card["cost"]):
			unlock_card(card_id)
			return true
	
	return false

# === СИСТЕМА СОХРАНЕНИЙ ===

func save_game():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_str = JSON.stringify(save_data)
		file.store_string(json_str)
		# print("Game saved.")

func load_game():
	if not FileAccess.file_exists(SAVE_PATH):
		return # Нет сохранения, используем дефолт
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json_str = file.get_as_text()
		var json = JSON.new()
		var parse_result = json.parse(json_str)
		
		if parse_result == OK:
			var loaded_data = json.get_data()
			# Обновляем безопасным способом (merge)
			if "money" in loaded_data: save_data["money"] = int(loaded_data["money"])
			if "unlocked_cards" in loaded_data: save_data["unlocked_cards"] = loaded_data["unlocked_cards"]
			print("Game loaded. Money: ", save_data["money"])
		else:
			print("JSON Parse Error: ", json.get_error_message())
