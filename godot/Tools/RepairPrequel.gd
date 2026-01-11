extends SceneTree

func _init():
	print("Starting Repair Prequel conversion...")
	var source_path = "res://Story/Legacy_TXT/prequel_danila.txt"
	var dest_path = "res://Story/prequel_danila.json"
	
	convert_file(source_path, dest_path)
	quit()

func convert_file(path: String, new_path: String):
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		print("Failed to open file: " + path)
		return
	
	var content = file.get_as_text()
	file.close()
	
	var lexer = SceneLexer.new()
	var tokens = lexer.tokenize(content)
	
	var parser = SceneParser.new()
	var tree = parser.parse(tokens)
	
	var json_data = serialize_tree(tree)
	
	var json_string = JSON.stringify(json_data, "\t")
	
	var out_file = FileAccess.open(new_path, FileAccess.WRITE)
	if out_file:
		out_file.store_string(json_string)
		out_file.close()
		print("Saved REPAIRED JSON to: " + new_path)
	else:
		print("Failed to save to: " + new_path)

func serialize_tree(tree: SceneParser.SyntaxTree) -> Array:
	var result = []
	for expr in tree.values:
		var serialized = serialize_expression(expr)
		if serialized:
			result.append(serialized)
	return result

func serialize_expression(expr):
	if expr == null: return null
	var type = expr.type
	match type:
		"Dialogue": return serialize_dialogue(expr)
		"Command": return serialize_command(expr)
		"Choice": return serialize_choice(expr)
		"ConditionalTree": return serialize_conditional(expr)
		_: return {"type": "unknown", "value": str(expr.value)}

func serialize_dialogue(expr: SceneParser.FunctionExpression) -> Dictionary:
	var node = {"type": "dialogue", "text": expr.value}
	var args = expr.arguments
	if args.size() > 0:
		node["character"] = get_arg_value(args[0])
		var arg_index = 1
		# Minimal serialization for repair
		while arg_index < args.size():
			var val = str(get_arg_value(args[arg_index]))
			if val == "": pass
			elif val in ["left", "right"]: node["side"] = val
			elif "mood" not in node: node["mood"] = val
			else: node["animation"] = val
			arg_index += 1
	return node

func serialize_command(expr: SceneParser.FunctionExpression) -> Dictionary:
	var args = []
	for arg in expr.arguments: args.append(get_arg_value(arg))
	return {"type": "command", "name": expr.value, "args": args}

func serialize_choice(expr: SceneParser.BaseExpression) -> Dictionary:
	var options = []
	for block in expr.value:
		options.append({"text": block.label, "children": serialize_block(block.value)})
	return {"type": "choice", "options": options}

func serialize_conditional(expr: SceneParser.ConditionalTreeExpression) -> Dictionary:
	var node = {"type": "if", "condition": get_condition_string(expr.if_block.value), "then": serialize_block(expr.if_block.block)}
	if expr.elif_block:
		node["elif"] = []
		for block in expr.elif_block:
			node["elif"].append({"condition": get_condition_string(block.value), "then": serialize_block(block.block)})
	if expr.else_block: node["else"] = serialize_block(expr.else_block.block)
	return node

func serialize_block(block_content: Array) -> Array:
	var result = []
	for item in block_content:
		var serialized = serialize_expression(item)
		if serialized: result.append(serialized)
	return result

func get_arg_value(arg):
	if arg is SceneParser.BaseExpression: return arg.value
	if typeof(arg) == TYPE_OBJECT and "value" in arg: return arg.value
	return str(arg)

func get_condition_string(val) -> String:
	if val is Array:
		var parts = []
		for item in val:
			var arg_val = get_arg_value(item)
			var is_string = false
			if typeof(item) == TYPE_OBJECT and "type" in item:
				if item.type == "String": is_string = true
			if is_string: parts.append('"' + str(arg_val) + '"')
			else: parts.append(str(arg_val))
		return "".join(parts)
	return str(val)
