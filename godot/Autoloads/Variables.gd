## Auto-loaded node that handles global variables
extends Node

const SAVE_FILE_LOCATION := "user://2DVisualNovelDemo.save"


func add_variable(_name: String, value) -> void:
	# Сначала читаем существующие данные
	var data: Dictionary = {variables = {}}
	
	if FileAccess.file_exists(SAVE_FILE_LOCATION):
		var read_file = FileAccess.open(SAVE_FILE_LOCATION, FileAccess.READ)
		if read_file:
			var json = JSON.new()
			var error = json.parse(read_file.get_as_text())
			if error == OK:
				data = json.data
			read_file.close()
	
	# Обновляем переменную
	if _name != "":
		if not data.has("variables"):
			data["variables"] = {}

		# Если value уже число или строка, сохраняем как есть
		# Если это строка с кодом, выполняем через _evaluate
		if value is int or value is float or value is String:
			data["variables"][_name] = value
		else:
			data["variables"][_name] = _evaluate(str(value))
	
	# Записываем обратно
	var write_file = FileAccess.open(SAVE_FILE_LOCATION, FileAccess.WRITE)
	if write_file:
		write_file.store_line(JSON.stringify(data))
		write_file.close()
		print("Variable saved: %s = %s" % [_name, data["variables"][_name]])
	else:
		push_error("Failed to open save file for writing: " + SAVE_FILE_LOCATION)


func get_stored_variables_list() -> Dictionary:
	# Stop if the save file doesn't exist
	if not FileAccess.file_exists(SAVE_FILE_LOCATION):
		return {}

	var save_file = FileAccess.open(SAVE_FILE_LOCATION, FileAccess.READ)
	var save_file_string = save_file.get_as_text()
	var test_json_conv = JSON.new()
	var parse_error = test_json_conv.parse(save_file_string)
	if parse_error != OK:
		print("JSON Parse Error: ", test_json_conv.get_error_message(), " at line ", test_json_conv.get_error_line())
		return {}

	var data: Dictionary = test_json_conv.data

	save_file.close()

	return data.variables


# Used to evaluate the variables' values
func _evaluate(input):
	var script = GDScript.new()
	script.set_source_code("func eval():\n\treturn " + input)
	script.reload()
	var obj = RefCounted.new()
	obj.set_script(script)
	return obj.eval()
