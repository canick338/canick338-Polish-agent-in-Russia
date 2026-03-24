## Auto-loaded node that handles global variables
extends Node

const SAVE_FILE_LOCATION := "user://2DVisualNovelDemo.save"


var _variables_cache: Dictionary = {}

func _ready() -> void:
	# Load variables into cache on startup
	_load_from_disk()

func clear_all_variables() -> void:
	_variables_cache.clear()
	_save_to_disk()

func load_variables(data: Dictionary) -> void:
	_variables_cache = data.duplicate()
	if _variables_cache.has("money"):
		_variables_cache.erase("money")
	_save_to_disk()

func _load_from_disk() -> void:
	if FileAccess.file_exists(SAVE_FILE_LOCATION):
		var read_file = FileAccess.open(SAVE_FILE_LOCATION, FileAccess.READ)
		if read_file:
			var json = JSON.new()
			var error = json.parse(read_file.get_as_text())
			if error == OK:
				var data = json.data
				if data.has("variables"):
					_variables_cache = data.variables
			read_file.close()

func add_variable(_name: String, value) -> void:
	# Update cache immediately
	if _name != "":
		# Handle mathematical modifiers like "+80" or "-500"
		if value is String and (value.begins_with("+") or value.begins_with("-")):
			var modifier_str = value.substr(1)
			if modifier_str.is_valid_float() or modifier_str.is_valid_int():
				var current_val = get_variable(_name, 0)
				if current_val is String:
					current_val = _evaluate(current_val)
				if not (current_val is int or current_val is float):
					current_val = 0
				
				var modifier = _evaluate(modifier_str)
				if value.begins_with("+"):
					_variables_cache[_name] = current_val + modifier
				elif value.begins_with("-"):
					_variables_cache[_name] = current_val - modifier
					
				if _name == "money":
					GameGlobal.player_money = _variables_cache[_name]
					return # GameGlobal saves its own state
					
				_save_to_disk()
				return
				
		# Если value уже число или строка, сохраняем как есть
		if value is int or value is float or value is String or value is bool:
			_variables_cache[_name] = value
		else:
			_variables_cache[_name] = _evaluate(str(value))
			
		if _name == "money":
			GameGlobal.player_money = _variables_cache[_name]
			return # GameGlobal handles saving
	
	# Save cache to disk
	_save_to_disk()

func _save_to_disk() -> void:
	var data = { "variables": _variables_cache }
	var write_file = FileAccess.open(SAVE_FILE_LOCATION, FileAccess.WRITE)
	if write_file:
		write_file.store_line(JSON.stringify(data))
		write_file.close()
		# print("Variables saved to disk.")
	else:
		push_error("Failed to open save file for writing: " + SAVE_FILE_LOCATION)

func get_stored_variables_list() -> Dictionary:
	# Return the in-memory cache directly but inject money
	var temp = _variables_cache.duplicate()
	temp["money"] = GameGlobal.player_money
	return temp

func get_variable(name: String, default = 0):
	if name == "money":
		return GameGlobal.player_money
	return _variables_cache.get(name, default)

# Safely converts a string value to the appropriate type
func _evaluate(input):
	var s = str(input).strip_edges()
	
	# Boolean
	if s == "true": return true
	if s == "false": return false
	
	# Integer
	if s.is_valid_int(): return int(s)
	
	# Float
	if s.is_valid_float(): return float(s)
	
	# Fallback: return as string
	return s
