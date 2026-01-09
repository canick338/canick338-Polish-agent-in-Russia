## Auto-loaded node that handles global variables
extends Node

const SAVE_FILE_LOCATION := "user://2DVisualNovelDemo.save"


var _variables_cache: Dictionary = {}

func _ready() -> void:
	# Load variables into cache on startup
	_load_from_disk()

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
		# Если value уже число или строка, сохраняем как есть
		# Если это строка с кодом, выполняем через _evaluate
		if value is int or value is float or value is String:
			_variables_cache[_name] = value
		else:
			_variables_cache[_name] = _evaluate(str(value))
	
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
	# Return the in-memory cache directly
	return _variables_cache


# Used to evaluate the variables' values
func _evaluate(input):
	var script = GDScript.new()
	script.set_source_code("func eval():\n\treturn " + input)
	script.reload()
	var obj = RefCounted.new()
	obj.set_script(script)
	return obj.eval()
