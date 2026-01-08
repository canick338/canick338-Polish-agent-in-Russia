extends Node

# Глобальный синглтон для хранения данных
# Доступен везде как 'GameGlobal'

signal card_unlocked(card_id)

# === БАЗА ДАННЫХ КАРТОЧЕК ===
# Здесь мы добавляем новые карточки.
# Формат: "id": { properties }
const CARD_DATABASE = {
	"card_danila": {
		"name": "Данила",
		"description": "Агент польской разведки под прикрытием. Прошел жесткую школу выживания на улицах Варшавы. Его цель — проникнуть на завод и выяснить правду.",
		"texture_path": "res://Characters/Danila/danila_thinking.png", # Using neutral/thinking as main portrait
		"unlock_type": "event"
	},
	"card_bronislav": {
		"name": "Бронислав",
		"description": "Начальник завода. Жесткий, подозрительный и не терпящий ошибок. Ходят слухи, что он замешан в темных делах.",
		"texture_path": "res://Characters/boss_of_factory/boss_of_factory.png",
		"unlock_type": "event"
	},
	"card_worker": {
		"name": "Рабочий",
		"description": "Типичный трудяга завода. Любит поиграть в карты после смены и пожаловаться на жизнь. Может знать больше, чем говорит.",
		"texture_path": "res://Characters/Worker/worker_neutral.png",
		"unlock_type": "event"
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
		card_unlocked.emit(card_id)



# === СИСТЕМА СОХРАНЕНИЙ ===

# === СИСТЕМА СОХРАНЕНИЙ ===

func get_save_path(slot_id: int) -> String:
	return "user://savegame_%d.dat" % slot_id

func save_game(slot_id: int = 0):
	var path = get_save_path(slot_id)
	var file = FileAccess.open(path, FileAccess.WRITE)
	
	# Добавляем метаданные
	var final_data = save_data.duplicate(true)
	final_data["timestamp"] = Time.get_datetime_string_from_system()
	
	# Сохраняем переменные сюжета (если есть синглтон Variables)
	if has_node("/root/Variables"):
		final_data["story_vars"] = get_node("/root/Variables").get_stored_variables_list()
	
	if file:
		var json_str = JSON.stringify(final_data)
		file.store_string(json_str)
		print("Game saved to slot ", slot_id)

func load_game(slot_id: int = 0) -> bool:
	var path = get_save_path(slot_id)
	if not FileAccess.file_exists(path):
		return false # Нет сохранения
	
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var json_str = file.get_as_text()
		var json = JSON.new()
		var parse_result = json.parse(json_str)
		
		if parse_result == OK:
			var loaded_data = json.get_data()
			
			# Обновляем безопасным способом (merge)
			if "money" in loaded_data: save_data["money"] = int(loaded_data["money"])
			if "unlocked_cards" in loaded_data: save_data["unlocked_cards"] = loaded_data["unlocked_cards"]
			
			# Загружаем сюжетные переменные
			if "story_vars" in loaded_data and has_node("/root/Variables"):
				var vars_node = get_node("/root/Variables")
				# Очищаем старые и загружаем новые
				# (Предполагаем наличие метода set_variables или делаем вручную)
				# TODO: Лучше добавить метод set_all в Variables.gd
				pass
				
			print("Game loaded from slot ", slot_id)
			return true
		else:
			print("JSON Parse Error: ", json.get_error_message())
	return false

func get_slot_info(slot_id: int) -> Dictionary:
	var path = get_save_path(slot_id)
	if not FileAccess.file_exists(path):
		return {"empty": true}
	
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var json = JSON.new()
		var parse_result = json.parse(file.get_as_text())
		if parse_result == OK:
			var data = json.get_data()
			var timestamp = data.get("timestamp", "???")
			return {"empty": false, "timestamp": timestamp, "money": data.get("money", 0)}
			
	return {"empty": true}
